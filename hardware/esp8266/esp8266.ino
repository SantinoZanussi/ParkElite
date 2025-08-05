// ESP8266 Parking Controller

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>
#include <SPI.h>
#include <MFRC522.h>

// --- CONFIGURACIÓN WIFI y API ---
const char* WIFI_SSID         = "rocaysalta";
const char* WIFI_PASSWORD     = "salta2043+";
const char* API_HOST_DOMAIN   = "parkelite-production.up.railway.app";
const uint16_t API_PORT_LOCAL = 3000;

// Códigos de error
#define ERROR_DATABASE_CONNECTION 1000
#define ERROR_EMPTY_RESPONSE 1001

static const char* ENDPOINT_CHECKCODE = "/api/reservas/checkCode";
static const char* ENDPOINT_CONFIRM_ARRIVAL = "/api/reservas/confirm-arrival";
static const char* ENDPOINT_CANCEL_RESERVATION = "/api/reservas/cancel-arrival";
static const char* ENDPOINT_CANCEL_SPECIFIC_RESERVATION = "/api/reservas/cancel";
static const char* ENDPOINT_GET_ACTIVE_RESERVATIONS = "/api/reservas/active-reservations";

// --- PINES ---
#define UART_RX_PIN   3
#define UART_TX_PIN   1

#define SS_PIN D4
#define RST_PIN D3

// --- OBJETOS ---
ESP8266WebServer server(80);
MFRC522 mfrc522(SS_PIN, RST_PIN);

const byte uid1[] = {0x03, 0x77, 0xFF, 0x13};

unsigned long lastRFIDCheck = 0;
unsigned long lastOccupancyCheck = 0;
unsigned long lastCancelCheck = 0;
unsigned long lastSyncCheck = 0;
const unsigned long RFID_CHECK_INTERVAL = 100;
const unsigned long OCCUPANCY_CHECK_INTERVAL = 5000;
const unsigned long CANCEL_CHECK_INTERVAL = 60000;
const unsigned long SYNC_CHECK_INTERVAL = 300000;

struct ActiveReservation {
  String reservationId;
  int spotNumber;
  unsigned long startTime;
  bool confirmed;
  String userCode;
};

ActiveReservation activeReservations[4];
bool spotOccupied[4] = {false, false, false, false};

// --- PROTOTIPOS ---
bool wifiConnect();
void handleSerial();
void setupWebServer();
void handleRoot();
void handleCodeSubmit();
void handleRFID();
bool esUIDValido(byte* uid);
void enviarComandoArduino(String comando);
String generateResultHTML(const String& title, const String& message, bool isError = false);
void checkOccupancyAndConfirm();
void checkAndCancelExpiredReservations();
void confirmArrival(String reservationId);
void cancelReservation(String reservationId);
void processOccupancyMessage(String message);
void addActiveReservation(String reservationId, int spotNumber, String userCode = "");
void syncActiveReservations();
void periodicSync();
void printReservationsStatus();

void setup() {
  Serial.begin(115200);
  Serial1.begin(9600);
  Serial.println("ESP8266 Parking Controller iniciando...");

  for (int i = 0; i < 4; i++) {
    activeReservations[i].reservationId = "";
    activeReservations[i].spotNumber = -1;
    activeReservations[i].startTime = 0;
    activeReservations[i].confirmed = false;
    activeReservations[i].userCode = "";
  }

  SPI.begin();
  mfrc522.PCD_Init();
  Serial.println("RFID RC522 inicializado");

  if (!wifiConnect()) {
    Serial.println("Error conectando WiFi");
    return;
  }

  setupWebServer();
  
  delay(3000);
  Serial.println("🔄 Iniciando sincronización inicial...");
  syncActiveReservations();
  
  Serial.println("Sistema listo");
  printReservationsStatus();
}

void loop() {
  server.handleClient();
  handleSerial();
  handleRFID();
  
  if (millis() - lastOccupancyCheck > OCCUPANCY_CHECK_INTERVAL) {
    checkOccupancyAndConfirm();
    lastOccupancyCheck = millis();
  }
  
  if (millis() - lastCancelCheck > CANCEL_CHECK_INTERVAL) {
    checkAndCancelExpiredReservations();
    lastCancelCheck = millis();
  }
  
  periodicSync();
}

// --- FUNCIONES ---

bool wifiConnect() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Conectando a WiFi");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(500);
    Serial.print('.');
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    return true;
  }
  return false;
}

void setupWebServer() {
  server.on("/", HTTP_GET, handleRoot);
  server.on("/submit", HTTP_POST, handleCodeSubmit);
  server.begin();
  Serial.println("Web server iniciado");
}

void handleRoot() {
String html = "<html><head>"
    "<meta charset='UTF-8'>"
    "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
    "<style>"
    "* { margin: 0; padding: 0; box-sizing: border-box; }"
    "body {"
        "font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;"
        "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
        "min-height: 100vh;"
        "display: flex;"
        "align-items: center;"
        "justify-content: center;"
        "padding: 20px;"
    "}"
    ".container {"
        "background: rgba(255, 255, 255, 0.95);"
        "backdrop-filter: blur(10px);"
        "border-radius: 20px;"
        "padding: 50px 40px;"
        "box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);"
        "max-width: 450px;"
        "width: 100%;"
        "text-align: center;"
        "border: 1px solid rgba(255, 255, 255, 0.2);"
    "}"
    ".lock-icon {"
        "width: 80px;"
        "height: 80px;"
        "margin: 0 auto 30px;"
        "border-radius: 50%;"
        "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
        "display: flex;"
        "align-items: center;"
        "justify-content: center;"
        "font-size: 40px;"
        "color: white;"
        "box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);"
    "}"
    "h1 {"
        "font-size: 28px;"
        "color: #2d3748;"
        "margin-bottom: 10px;"
        "font-weight: 600;"
    "}"
    ".subtitle {"
        "color: #718096;"
        "font-size: 16px;"
        "margin-bottom: 40px;"
        "line-height: 1.5;"
    "}"
    "form {"
        "display: flex;"
        "flex-direction: column;"
        "gap: 25px;"
    "}"
    ".input-group {"
        "position: relative;"
        "text-align: left;"
    "}"
    "label {"
        "display: block;"
        "font-size: 14px;"
        "font-weight: 600;"
        "color: #4a5568;"
        "margin-bottom: 8px;"
    "}"
    "input[type='text'] {"
        "width: 100%;"
        "padding: 16px 20px;"
        "border: 2px solid #e2e8f0;"
        "border-radius: 12px;"
        "font-size: 18px;"
        "font-weight: 600;"
        "letter-spacing: 2px;"
        "text-align: center;"
        "background: rgba(255, 255, 255, 0.8);"
        "transition: all 0.3s ease;"
        "outline: none;"
    "}"
    "input[type='text']:focus {"
        "border-color: #667eea;"
        "background: white;"
        "box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);"
        "transform: translateY(-1px);"
    "}"
    "input[type='submit'] {"
        "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
        "color: white;"
        "border: none;"
        "padding: 18px 30px;"
        "border-radius: 12px;"
        "font-size: 16px;"
        "font-weight: 600;"
        "cursor: pointer;"
        "transition: all 0.3s ease;"
        "box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);"
        "text-transform: uppercase;"
        "letter-spacing: 1px;"
    "}"
    "input[type='submit']:hover {"
        "transform: translateY(-2px);"
        "box-shadow: 0 8px 25px rgba(102, 126, 234, 0.6);"
    "}"
    "input[type='submit']:active {"
        "transform: translateY(0);"
    "}"
    ".security-info {"
        "margin-top: 30px;"
        "padding: 20px;"
        "background: rgba(102, 126, 234, 0.1);"
        "border-radius: 12px;"
        "border-left: 4px solid #667eea;"
    "}"
    ".security-info p {"
        "color: #4a5568;"
        "font-size: 14px;"
        "line-height: 1.6;"
        "margin: 0;"
    "}"
    ".code-hint {"
        "font-size: 12px;"
        "color: #718096;"
        "margin-top: 5px;"
        "font-style: italic;"
    "}"
    ".rfid-info {"
        "margin-top: 20px;"
        "padding: 15px;"
        "background: rgba(76, 175, 80, 0.1);"
        "border-radius: 12px;"
        "border-left: 4px solid #4caf50;"
    "}"
    ".rfid-info p {"
        "color: #2e7d32;"
        "font-size: 13px;"
        "line-height: 1.5;"
        "margin: 0;"
    "}"
    "@media (max-width: 480px) {"
        ".container { padding: 40px 25px; }"
        "h1 { font-size: 24px; }"
        ".subtitle { font-size: 14px; }"
        ".lock-icon { width: 60px; height: 60px; font-size: 30px; }"
        "input[type='text'] { font-size: 16px; padding: 14px 16px; }"
        "input[type='submit'] { padding: 16px 25px; font-size: 14px; }"
    "}"
    "</style>"
    "</head><body>"
    "<div class='container'>"
        "<div class='lock-icon'>🔐</div>"
        "<h1>Control de Acceso</h1>"
        "<p class='subtitle'>Ingrese su código de 6 dígitos para continuar</p>"
        "<form action='/submit' method='POST'>"
            "<div class='input-group'>"
                "<label for='code'>Código de Acceso</label>"
                "<input type='text' id='code' name='code' maxlength='6' pattern='[0-9]{6}' placeholder='000000' required>"
                "<p class='code-hint'>Solo números, exactamente 6 dígitos</p>"
            "</div>"
            "<input type='submit' value='Verificar Código'>"
        "</form>"
        "<div class='security-info'>"
            "<p><strong>🛡️ Acceso Seguro:</strong> Este sistema verifica su identidad mediante un código único de 6 dígitos.</p>"
        "</div>"
        "<div class='rfid-info'>"
            "<p><strong>📡 RFID Activo:</strong> También puede acercar su tarjeta RFID al lector para acceso automático.</p>"
        "</div>"
    "</div>"
    "</body></html>";
  server.send(200, "text/html", html);
}

void handleCodeSubmit() {
  if (!server.hasArg("code")) {
    server.send(200, "text/html", generateResultHTML("Error", "Falta código", true));
    return;
  }
  String code = server.arg("code");

  // Construir JSON
  StaticJsonDocument<128> j;
  j["code"] = code;
  String payload;
  serializeJson(j, payload);

  Serial.print("Payload JSON: "); Serial.println(payload);

  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CHECKCODE;
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  int statusCode = http.POST(payload);
  String resp = (statusCode > 0) ? http.getString() : "";
  http.end();

  Serial.print("HTTP Status: "); Serial.println(statusCode);
  Serial.print("Respuesta JSON: "); Serial.println(resp);

  if (statusCode == -1) {
    Serial.println("Error de conexión con la base de datos");
    server.send(200, "text/html", generateResultHTML("Error", "No se pudo conectar con la base de datos. Código de error: " + String(ERROR_DATABASE_CONNECTION), true));
    return;
  }

  if (resp.length() == 0) {
    Serial.println("Respuesta vacía del servidor");
    server.send(200, "text/html", generateResultHTML("Error", "El servidor no respondió. Código de error: " + String(ERROR_EMPTY_RESPONSE), true));
    return;
  }

  StaticJsonDocument<256> res;
  DeserializationError err = deserializeJson(res, resp);
  if (err) {
    Serial.print("Error al parsear JSON: ");
    Serial.println(err.c_str());
    server.send(200, "text/html", generateResultHTML("Error", "Error interno al procesar la respuesta", true));
    return;
  }

  bool allowed = res["allowed"];
  int spotNumber = res.containsKey("spotNumber") ? res["spotNumber"].as<int>() : -1;
  String reservationId = res.containsKey("reservationId") ? res["reservationId"].as<String>() : "";

  String cmd = allowed ? String("ABRIR") : "DENY";
  enviarComandoArduino(cmd);

  if (allowed && spotNumber > 0 && reservationId.length() > 0) {
    addActiveReservation(reservationId, spotNumber, code);
  }

  String msg = allowed ? "Acceso permitido a la plaza " + String(spotNumber)
                       : "Acceso denegado";
  server.send(200, "text/html", generateResultHTML(allowed ? "Éxito" : "Acceso denegado", msg, !allowed));
}

void handleRFID() {
  if (millis() - lastRFIDCheck < RFID_CHECK_INTERVAL) {
    return;
  }
  lastRFIDCheck = millis();

  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  Serial.print("RFID Tag detectado: ");
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    Serial.print(mfrc522.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(mfrc522.uid.uidByte[i], HEX);
  }
  Serial.println();

  if (esUIDValido(mfrc522.uid.uidByte)) {
    Serial.println("✅ RFID Tag válido, enviando orden...");
    enviarComandoArduino("ABRIR");
    delay(1000);
  } else {
    Serial.println("❌ RFID Tag no reconocido.");
  }

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void checkOccupancyAndConfirm() {
  enviarComandoArduino("CONSULTAR_OCUPACION");
  
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() > 0 && 
        !activeReservations[i].confirmed &&
        spotOccupied[activeReservations[i].spotNumber - 1]) {
      
      confirmArrival(activeReservations[i].reservationId);
      activeReservations[i].confirmed = true;
      Serial.println("Llegada confirmada para reserva " + activeReservations[i].reservationId);
    }
  }
}

void checkAndCancelExpiredReservations() {
  unsigned long currentTime = millis();
  
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() > 0 && 
        !activeReservations[i].confirmed &&
        (currentTime - activeReservations[i].startTime) > 1200000) {
      
      cancelReservation(activeReservations[i].reservationId);
      Serial.println("Reserva cancelada por expiración: " + activeReservations[i].reservationId);
      
      activeReservations[i].reservationId = "";
      activeReservations[i].spotNumber = -1;
      activeReservations[i].startTime = 0;
      activeReservations[i].confirmed = false;
      activeReservations[i].userCode = "";
    }
  }
}

void confirmArrival(String reservationId) {
  Serial.print("Confirmando llegada: ");
  Serial.println(reservationId);
  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CONFIRM_ARRIVAL + "/" + reservationId;
  
  StaticJsonDocument<128> doc;
  doc["reservationId"] = reservationId;
  String payload;
  serializeJson(doc, payload);
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  int statusCode = http.POST(payload);
  http.end();
  
  Serial.print("Confirmación de llegada - Status: ");
  Serial.println(statusCode);
}

void cancelReservation(String reservationId) {
  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CANCEL_SPECIFIC_RESERVATION + "/" + reservationId;
  
  StaticJsonDocument<128> doc;
  doc["reservationId"] = reservationId;
  
  String payload;
  serializeJson(doc, payload);
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  int statusCode = http.POST(payload);
  http.end();
  
  Serial.print("Cancelación de reserva - Status: ");
  Serial.println(statusCode);
}

void addActiveReservation(String reservationId, int spotNumber, String userCode) {
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId == reservationId) {
      activeReservations[i].spotNumber = spotNumber;
      activeReservations[i].startTime = millis();
      activeReservations[i].confirmed = false;
      activeReservations[i].userCode = userCode;
      Serial.println("Reserva actualizada: " + reservationId + " - Plaza: " + String(spotNumber));
      return;
    }
  }
  
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() == 0) {
      activeReservations[i].reservationId = reservationId;
      activeReservations[i].spotNumber = spotNumber;
      activeReservations[i].startTime = millis();
      activeReservations[i].confirmed = false;
      activeReservations[i].userCode = userCode;
      Serial.println("Reserva activa agregada: " + reservationId + " - Plaza: " + String(spotNumber) + " - Código: " + userCode);
      break;
    }
  }
}

void syncActiveReservations() {
  Serial.println("🔄 Sincronizando reservas activas con la base de datos...");
  
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("❌ WiFi desconectado, reintentando...");
    if (!wifiConnect()) {
      Serial.println("❌ No se pudo reconectar WiFi");
      return;
    }
  }
  
  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_GET_ACTIVE_RESERVATIONS;
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(10000);
  
  int statusCode = http.GET();
  String response = (statusCode > 0) ? http.getString() : "";
  http.end();
  
  Serial.print("Status de sincronización: ");
  Serial.println(statusCode);
  
  if (statusCode != 200) {
    Serial.println("❌ Error al obtener reservas activas - Status: " + String(statusCode));
    return;
  }
  
  if (response.length() == 0) {
    Serial.println("❌ Respuesta vacía del servidor");
    return;
  }
  
  Serial.print("Respuesta recibida (primeros 200 chars): ");
  Serial.println(response.substring(0, 200));
  
  StaticJsonDocument<1024> doc;
  DeserializationError error = deserializeJson(doc, response);
  
  if (error) {
    Serial.print("❌ Error al parsear JSON de reservas: ");
    Serial.println(error.c_str());
    return;
  }
  
  if (!doc["success"].as<bool>()) {
    Serial.println("❌ Respuesta del servidor indica error");
    String message = doc["message"].as<String>();
    if (message.length() > 0) {
      Serial.println("Mensaje del servidor: " + message);
    }
    return;
  }
  
  String serverTime = doc["serverTimeUTC"].as<String>();
  if (serverTime.length() > 0) {
    Serial.println("🕐 Hora del servidor (UTC): " + serverTime);
  }
  
  int reservationCount = doc["count"].as<int>();
  Serial.println("📊 Reservas disponibles en servidor: " + String(reservationCount));
  
  for (int i = 0; i < 4; i++) {
    activeReservations[i].reservationId = "";
    activeReservations[i].spotNumber = -1;
    activeReservations[i].startTime = 0;
    activeReservations[i].confirmed = false;
    activeReservations[i].userCode = "";
  }
  
  JsonArray reservations = doc["reservations"].as<JsonArray>();
  int index = 0;
  
  for (JsonObject reservation : reservations) {
    if (index >= 4) break;
    
    String reservationId = reservation["_id"].as<String>();
    String status = reservation["status"].as<String>();
    String userCode = String(reservation["code"].as<int>());
    
    JsonObject parkingSpot = reservation["parkingSpotId"];
    int spotNumber = parkingSpot["spotNumber"].as<int>();
    
    if (reservationId.length() > 0 && spotNumber > 0) {
      activeReservations[index].reservationId = reservationId;
      activeReservations[index].spotNumber = spotNumber;
      activeReservations[index].startTime = millis();
      activeReservations[index].confirmed = (status == "confirmado");
      activeReservations[index].userCode = userCode;
      
      Serial.println("✅ Reserva cargada:");
      Serial.println("   - ID: " + reservationId);
      Serial.println("   - Código: " + userCode);
      Serial.println("   - Plaza: " + String(spotNumber));
      Serial.println("   - Estado: " + status);
      
      index++;
    }
  }
  
  Serial.println("🔄 Sincronización completada. Total reservas cargadas: " + String(index));
  printReservationsStatus();
}

void periodicSync() {
  if (millis() - lastSyncCheck > SYNC_CHECK_INTERVAL) {
    syncActiveReservations();
    lastSyncCheck = millis();
  }
}

void printReservationsStatus() {
  Serial.println("📋 Estado actual de reservas:");
  bool hasReservations = false;
  
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() > 0) {
      hasReservations = true;
      Serial.println("  Slot " + String(i + 1) + ":");
      Serial.println("    - ID: " + activeReservations[i].reservationId);
      Serial.println("    - Plaza: " + String(activeReservations[i].spotNumber));
      Serial.println("    - Código: " + activeReservations[i].userCode);
      Serial.println("    - Confirmado: " + String(activeReservations[i].confirmed ? "Sí" : "No"));
      Serial.println("    - Tiempo: " + String((millis() - activeReservations[i].startTime) / 1000) + "s");
    }
  }
  
  if (!hasReservations) {
    Serial.println("  No hay reservas activas");
  }
}

bool esUIDValido(byte* uid) {
  bool esUID1 = true;
  for (byte i = 0; i < 4; i++) {
    if (uid[i] != uid1[i]) {
      esUID1 = false;
      break;
    }
  }
  if (esUID1) return true;

  return false;
}

void enviarComandoArduino(String comando) {
  Serial1.println(comando);
  Serial.print("Comando enviado a Arduino: ");
  Serial.println(comando);
}

String generateResultHTML(const String& title, const String& message, bool isError) {
      String html = "<html><head>"
        "<meta charset='UTF-8'>"
        "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
        "<style>"
        "* { margin: 0; padding: 0; box-sizing: border-box; }"
        "body {"
            "font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;"
            "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
            "min-height: 100vh;"
            "display: flex;"
            "align-items: center;"
            "justify-content: center;"
            "padding: 20px;"
        "}"
        ".container {"
            "background: rgba(255, 255, 255, 0.95);"
            "backdrop-filter: blur(10px);"
            "border-radius: 20px;"
            "padding: 40px 30px;"
            "box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);"
            "max-width: 500px;"
            "width: 100%;"
            "text-align: center;"
            "border: 1px solid rgba(255, 255, 255, 0.2);"
        "}"
        ".icon {"
            "width: 80px;"
            "height: 80px;"
            "margin: 0 auto 20px;"
            "border-radius: 50%;"
            "display: flex;"
            "align-items: center;"
            "justify-content: center;"
            "font-size: 40px;"
            "font-weight: bold;"
        "}"
        ".icon-success {"
            "background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);"
            "color: white;"
        "}"
        ".icon-error {"
            "background: linear-gradient(135deg, #ff6b6b 0%, #ffa500 100%);"
            "color: white;"
        "}"
        "h3 {"
            "font-size: 28px;"
            "margin-bottom: 15px;"
            "font-weight: 600;"
        "}"
        ".title-success { color: #2d5a87; }"
        ".title-error { color: #c53030; }"
        "p {"
            "font-size: 16px;"
            "line-height: 1.6;"
            "margin-bottom: 30px;"
            "color: #4a5568;"
        "}"
        ".btn {"
            "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
            "color: white;"
            "border: none;"
            "padding: 15px 30px;"
            "border-radius: 50px;"
            "font-size: 16px;"
            "font-weight: 600;"
            "cursor: pointer;"
            "transition: all 0.3s ease;"
            "box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);"
            "text-decoration: none;"
            "display: inline-block;"
        "}"
        ".btn:hover {"
            "transform: translateY(-2px);"
            "box-shadow: 0 8px 25px rgba(102, 126, 234, 0.6);"
        "}"
        ".btn:active {"
            "transform: translateY(0);"
        "}"
        "@media (max-width: 480px) {"
            ".container { padding: 30px 20px; }"
            "h3 { font-size: 24px; }"
            "p { font-size: 14px; }"
            ".icon { width: 60px; height: 60px; font-size: 30px; }"
        "}"
        "</style>"
        "</head><body>"
        "<div class='container'>"
        "<div class='icon ";
    
    html += isError ? "icon-error'>✕" : "icon-success'>✓";
    
    html += "</div>"
        "<h3 class='";
    
    html += isError ? "title-error" : "title-success";
    
    html += "'>";
    html += title;
    html += "</h3><p>";
    html += message;
    html += "</p>"
        "<button class='btn' onclick=\"window.location.href='/';\">Volver al formulario</button>"
        "</div></body></html>";
        
    return html;
}

void handleSerial() {
  if (!Serial1.available()) return;
  String msg = Serial1.readStringUntil('\n');
  msg.trim();
  Serial.print("Serial recv: ");
  Serial.println(msg);
  
  if (msg.startsWith("OCUPACION_CONFIRMADA_")) {
    int spotNum = msg.substring(21).toInt();
    if (spotNum >= 1 && spotNum <= 4) {
      spotOccupied[spotNum - 1] = true;
      Serial.println("Plaza " + String(spotNum) + " ocupada confirmada");
    }
  }
  else if (msg.startsWith("LIBERADO_")) {
    int spotNum = msg.substring(9).toInt();
    if (spotNum >= 1 && spotNum <= 4) {
      spotOccupied[spotNum - 1] = false;
      Serial.println("Plaza " + String(spotNum) + " liberada");
      
      for (int i = 0; i < 4; i++) {
        if (activeReservations[i].spotNumber == spotNum && activeReservations[i].confirmed) {
          Serial.println("Limpiando reserva completada: " + activeReservations[i].reservationId);
          activeReservations[i].reservationId = "";
          activeReservations[i].spotNumber = -1;
          activeReservations[i].startTime = 0;
          activeReservations[i].confirmed = false;
          activeReservations[i].userCode = "";
          break;
        }
      }
    }
  }
  else if (msg.startsWith("ESTADO_OCUPACION:")) {
    String estados = msg.substring(17);
    for (int i = 0; i < 4 && i * 2 < estados.length(); i++) {
      char estado = estados.charAt(i * 2);
      spotOccupied[i] = (estado == '1');
    }
    Serial.println("Estado de ocupación actualizado");
  }
  else if (msg.startsWith("SYSTEM_STATUS")) {
    Serial.println("📊 Estado del sistema solicitado por Arduino");
    printReservationsStatus();
  }
}