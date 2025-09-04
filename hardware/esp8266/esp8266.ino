// --- ESP8266 - ParkElite (1.0) ---

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>
#include <SPI.h>
#include <MFRC522.h>

// --- CONFIGURACIÓN ---
const char* WIFI_SSID         = "rocaysalta";
const char* WIFI_PASSWORD     = "salta2043+";
const char* API_HOST_DOMAIN   = "parkelite-production.up.railway.app";

// --- RUTAS API ---
static const char* ENDPOINT_CHECKCODE = "/api/reservas/checkCode";
static const char* ENDPOINT_CONFIRM_ARRIVAL = "/api/reservas/confirm-arrival";
static const char* ENDPOINT_CANCEL_RESERVATION = "/api/reservas/cancel-arrival";
static const char* ENDPOINT_CANCEL_SPECIFIC_RESERVATION = "/api/reservas/cancel";
static const char* ENDPOINT_GET_ACTIVE_RESERVATIONS = "/api/reservas/active-reservations";

// --- PINES RFID ---
#define SS_PIN D8
#define RST_PIN D4

// --- SERVIDOR WEB, LOGGER, Y LECTOR RFID ---
WiFiServer telnetServer(23);
WiFiClient telnetClient;
ESP8266WebServer server(80);
MFRC522 mfrc522(SS_PIN, RST_PIN);

// --- RFIDs AUTORIZADOS ---
const byte uid1[] = {0x03, 0x77, 0xFF, 0x13};

// --- TIEMPOS ---
unsigned long ultRFIDCheck = 0;
unsigned long ultOcupacionPlazaCheck = 0;
unsigned long ultPing = 0;
unsigned long ultReservasCheck = 0;

const unsigned long TIEMPO_CHECK_RFID = 100;
const unsigned long TIEMPO_CHECK_OCUPACION = 5000;
const unsigned long TIEMPO_PING = 1000;
const unsigned long TIEMPO_OBTENER_RESERVAS = 150000;

// --- VARIABLES BASE ---
struct ActiveReservation {
  String reservationId;
  int spotNumber;
  unsigned long startTime;
  bool confirmed;
  String userCode;
};

bool arduinoConectado = false;
ActiveReservation activeReservations[4];
bool spotOccupied[4] = {false, false, false, false};
int spotMapping[4] = {3, 4, 5, 6}; // Plazas

// --- PROTOTIPOS ---
bool wifiConnect();
void setupWebServer();
void webPrincipal();
void webCodigo();
void RFID();
bool esUIDValido(byte* uid);
void enviarComandoArduino(String comando);
String generateResultHTML(const String& title, const String& message, bool isError = false);
void confirmarLlegada(String reservationId);
void cancelarReserva(String reservationId);
void procesarComandosArduino(String message);
void obtenerReservasActivas();
void mostrarEstadosReservas();
void checkOcupacionesYConfirmar();
void checkReservasExpiradasCanceladas();
bool Arduino();
int getSpotIndex(int spotNumber);

void setup() {
  Serial.begin(9600);
  delay(200);
  
  // --- WIFI ---
  if (!wifiConnect()) { telnetLog("❌ Error al conectar el WiFi") return; }

  telnetServer.begin();
  telnetServer.setNoDelay(true);

  telnetLog("❗ ESP8266 - ParkElite v1.0 iniciando...");

  // --- ARDUINO ---
  unsigned long ultAviso = millis();
  telnetLog("🔌 Conectando con Arduino... (ESP8266)");
  while (!arduinoConectado) {
    Arduino();

    if (millis() - ultAviso >= 10000) {
      telnetLog("⏳ Esperando conexión con Arduino... (ESP8266)");
      ultAviso = millis();
    }

    delay(100);
  }

  // --- INICIALIZAR RESERVAS DE FORMA LOCAL ---
  for (int i = 0; i < 4; i++) {
    activeReservations[i].reservationId = "";
    activeReservations[i].spotNumber = -1;
    activeReservations[i].startTime = 0;
    activeReservations[i].confirmed = false;
    activeReservations[i].userCode = "";
  }
  telnetLog("✅ Variables locales inicializadas (ESP8266)");
  
  // --- RFID ---
  SPI.begin();
  mfrc522.PCD_Init();
  telnetLog("✅ RFID RC522 inicializado (ESP8266)");

  // --- RESERVAS ---
  delay(2000);
  telnetLog("🔄 Iniciando sincronización inicial... (ESP8266)");
  obtenerReservasActivas();
  
  // --- SERVIDOR WEB ---
  if (!setupWebServer()) { telnetLog("❌ Error al iniciar el servidor web"); return;}
  
  telnetLog("✅ Sistema iniciado (ESP8266)");
}

void loop() {
  // --- TELNET LOGGER ---
  WiFiClient newClient = telnetServer.available();
  if (newClient) {
    if (!telnetClient || !telnetClient.connected()) {
      if (telnetClient) telnetClient.stop();
      telnetClient = newClient;
      telnetLog("== Cliente Telnet conectado ==");
      telnetLog(String("IP: ") + telnetClient.remoteIP().toString());
    } else {
      // rechazar clientes extras
      newClient.stop();
    }
  }
  // --- SOLICITUDES HTTP --
  server.handleClient();
  
  // --- OTROS --
  Arduino();
  RFID();
  
  // --- ACTUALIZAR RESERVAS CADA 15M --
 if (millis() - ultReservasCheck > TIEMPO_OBTENER_RESERVAS) {
   obtenerReservasActivas();
   ultReservasCheck = millis();
  }
}

// --- FUNCIONES ---

void telnetLog(const String &msg) {
  if (telnetClient && telnetClient.connected()) {
    telnetClient.println(msg);
  }
}

bool esUIDValido(byte* uid) {
  for (byte i = 0; i < 4; i++) {
    if (uid[i] != uid1[i]) return false;
  }
  return true;
}

bool wifiConnect() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  telnetLog("🔌 Conectando WiFi (ESP8266)");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(500);
    telnetLog('.');
  }
  telnetLog();
  if (WiFi.status() == WL_CONNECTED) {
    telnetLog("✅ WiFi conectado (ESP8266)");
    telnetLog("💻 IPv4: ");
    telnetLog(WiFi.localIP());
    return true;
  }
  return false;
}

// --- EVENTOS ---

void Arduino() {
  if (millis() - ultPing >= TIEMPO_PING) {
    Serial.println("PING");
    ultPing = millis();
    telnetLog("→ PING enviado");
  }

  while (Serial.available()) {
    String mensaje = Serial.readStringUntil('\n');
    mensaje.trim();
    if (mensaje.length() > 0) {
      telnetLog("← ARDUINO: " + mensaje);
      procesarComandosArduino(mensaje);
    }
  }
}

void setupWebServer() {
  server.on("/", HTTP_GET, webPrincipal);
  server.on("/submit", HTTP_POST, webCodigo);
  server.on("/status", HTTP_GET, []() {
    String status = "{\"arduino\":";
    status += arduinoConectado ? "true" : "false";
    status += ",\"wifi\":";
    status += (WiFi.status() == WL_CONNECTED) ? "true" : "false";
    status += ",\"activeReservations\":";
    
    int count = 0;
    for (int i = 0; i < 4; i++) {
      if (activeReservations[i].reservationId.length() > 0) count++;
    }
    status += String(count) + "}";
    
    server.send(200, "application/json", status);
  });
  server.begin();
  telnetLog("✅ Servidor web iniciado (ESP8266)");
}

void mostrarEstadosReservas() {
  telnetLog("📋 Estado actual de reservas: (ESP8266)");
  bool hasReservations = false;
  
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() > 0) {
      hasReservations = true;
      telnetLog("  Slot " + String(i + 1) + ":");
      telnetLog("    - ID: " + activeReservations[i].reservationId);
      telnetLog("    - Plaza: " + String(activeReservations[i].spotNumber));
      telnetLog("    - Código: " + activeReservations[i].userCode);
      telnetLog("    - Confirmado: " + String(activeReservations[i].confirmed ? "Sí" : "No"));
      telnetLog("    - Tiempo: " + String((millis() - activeReservations[i].startTime) / 1000) + "s");
    }
  }
  
  if (!hasReservations) {
    telnetLog("😑 No hay reservas activas (ESP8266)");
  }

  telnetLog("🔌 Arduino: " + String(arduinoConnected ? "Conectado" : "Desconectado"));
  
  telnetLog("🚗 Ocupación: [");
  for (int i = 0; i < 4; i++) {
    telnetLog(spotOccupied[i] ? "●" : "○");
    if (i < 3) telnetLog(",");
  }
  telnetLog("] (Plazas " + String(spotMapping[0]) + "," + String(spotMapping[1]) + "," + 
                String(spotMapping[2]) + "," + String(spotMapping[3]) + ")");
}

void RFID() {
  if (millis() - ultRFIDCheck < TIEMPO_CHECK_RFID) return;
  ultRFIDCheck = millis();

  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) return;

  if (esUIDValido(mfrc522.uid.uidByte)) {
    telnetLog("✅ RFID Tag válido, enviando orden... (ESP8266)");
    if (arduinoConectado) {
      enviarComandoArduino("ABRIR");
    } else {
      telnetLog("⚠️ Arduino desconectado (ESP8266)");
    }
    delay(1000);
  }

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void confirmarLlegada(String reservationId) {
  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CONFIRM_ARRIVAL + "/" + reservationId;
  
  StaticJsonDocument<128> doc;
  doc["reservationId"] = reservationId;
  String payload;
  serializeJson(doc, payload);
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000);
  int statusCode = http.POST(payload);
  http.end();
  
  telnetLog("🚗 Confirmación de llegada - Status: " + String(statusCode));
}

void cancelarReserva(String reservationId) {
  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CANCEL_SPECIFIC_RESERVATION + "/" + reservationId;
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000);
  int statusCode = http.DELETE();
  http.end();
  
  telnetLog("Cancelación de reserva - Status: " + String(statusCode));
}

void checkOcupacionesYConfirmar() {
  if (!arduinoConnected) return;
  
  enviarComandoArduino("CONSULTAR_OCUPACION");
  
  // checkear confirmaciones pendientes
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() > 0 && 
        !activeReservations[i].confirmed) {
      
      int spotIndex = getSpotIndex(activeReservations[i].spotNumber);
      if (spotIndex >= 0 && spotOccupied[spotIndex]) {
        confirmarLlegada(activeReservations[i].reservationId);
        activeReservations[i].confirmed = true;
        telnetLog("✅ Llegada confirmada para reserva " + activeReservations[i].reservationId + 
                      " en plaza " + String(activeReservations[i].spotNumber));
      }
    }
  }
}

void checkReservasExpiradasCanceladas() {
  unsigned long currentTime = millis();
  
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() > 0 && 
        !activeReservations[i].confirmed &&
        (currentTime - activeReservations[i].startTime) > 1200000) { // 20 minutos
      
      telnetLog("⏰ Cancelando reserva expirada: " + activeReservations[i].reservationId);
      cancelarReserva(activeReservations[i].reservationId);
      
      // limpiar reserva local
      activeReservations[i].reservationId = "";
      activeReservations[i].spotNumber = -1;
      activeReservations[i].startTime = 0;
      activeReservations[i].confirmed = false;
      activeReservations[i].userCode = "";
    }
  }
}

// --- MENSAJES ---

void procesarComandosArduino(String message) {
  /*
  ESP8266 → ARDUINO:
  PING	Comando de verificación de conexión. Arduino responde con PONG si está activo.
  ABRIR	Orden para abrir la barrera. Arduino abre el servo 5 segundos y luego lo cierra automáticamente.
  CONSULTAR_OCUPACION	Solicita el estado de ocupación de las plazas. Arduino responde con ESTADO_OCUPACION:....
  STATUS_REQUEST	Solicita el estado completo del sistema (sensores y barrera). Arduino responde con SYSTEM_STATUS:....
  RESET_SENSORS	Orden para reiniciar/resetear todos los sensores de ocupación. Arduino responde con SENSORS_RESET_OK.

  ARDUINO → ESP8266:
  PONG	Respuesta al PING enviado por ESP, confirma que Arduino está conectado.
  BARRERA_ABIERTA	Confirma que la barrera fue abierta (respuesta al comando ABRIR).
  SENSOR_DETECTING:<n>	Notifica que un sensor detectó un vehículo en la plaza <n>. Estado inicial antes de confirmar ocupación.
  OCUPACION_CONFIRMADA:<n>	Confirma que la plaza <n> está ocupada después del tiempo de confirmación (60s).
  LIBERADO:<n>	Notifica que la plaza <n> se liberó.
  ESTADO_OCUPACION:<estados>:<plazas>	Envía el estado de ocupación de todas las plazas (1 = ocupada, 0 = libre). Incluye correspondencia de IDs de plaza.
  SYSTEM_STATUS:SENSORS_OK:<estados>:BARRIER_OK:1	Estado completo de sensores y barrera. Indica si sensores están funcionando y si barrera está operativa.
  SENSORS_RESET_OK	Confirma que los sensores fueron reseteados tras el comando RESET_SENSORS.
  */

  if (message == "PONG") {
    arduinoConectado = true;
    ultPing = millis();
    //enviarComandoArduino("STATUS_REQUEST");
  }
  else if (message == "BARRERA_ABIERTA") {
    telnetLog("✅ Barrera abierta confirmada");
  }
  else if (message.startsWith("OCUPACION_CONFIRMADA:")) {
    int spotNumber = message.substring(21).toInt();
    int spotIndex = getSpotIndex(spotNumber);
    if (spotIndex >= 0) {
      spotOccupied[spotIndex] = true;
      telnetLog("🚗 Plaza " + String(spotNumber) + " ocupada confirmada");
    }
  }
  else if (message.startsWith("LIBERADO:")) {
    int spotNumber = message.substring(9).toInt();
    int spotIndex = getSpotIndex(spotNumber);
    if (spotIndex >= 0) {
      spotOccupied[spotIndex] = false;
      telnetLog("🅿️ Plaza " + String(spotNumber) + " liberada");
      
      // Limpiar reserva confirmada
      for (int i = 0; i < 4; i++) {
        if (activeReservations[i].spotNumber == spotNumber && activeReservations[i].confirmed) {
          telnetLog("Limpiando reserva completada: " + activeReservations[i].reservationId);
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
  else if (message.startsWith("SENSOR_DETECTING:")) {
    int spotNumber = message.substring(17).toInt();
    telnetLog("👁️ Detectando vehículo en plaza " + String(spotNumber));
  }
  else if (message.startsWith("ESTADO_OCUPACION:")) {
    String data = message.substring(17);
    int colonPos = data.indexOf(':');
    
    if (colonPos > 0) {
      String estados = data.substring(0, colonPos);
      String plazas = data.substring(colonPos + 1);
      
      // Actualizar estados
      for (int i = 0; i < 4 && i * 2 < estados.length(); i++) {
        char estado = estados.charAt(i * 2);
        spotOccupied[i] = (estado == '1');
      }
      
      telnetLog("📊 Estado ocupación actualizado: " + estados + " (Plazas: " + plazas + ")");
    }
  }
  else if (message.startsWith("SYSTEM_STATUS:")) {
    telnetLog("🔧 Estado del sistema Arduino recibido");
  }
  else if (message == "SENSORS_RESET_OK") {
    telnetLog("✅ Sensores Arduino reseteados");
  }
  else {
    telnetLog("🤔 Mensaje desconocido de Arduino: " + message);
  }
}

int getSpotIndex(int spotNumber) {
  for (int i = 0; i < 4; i++) {
    if (spotMapping[i] == spotNumber) {
      return i;
    }
  }
  return -1; // No encontrado
}

void obtenerReservasActivas() {
  telnetLog("🔄 Sincronizando reservas activas... (ESP8266)");
  
  if (WiFi.status() != WL_CONNECTED) {
    telnetLog("❌ WiFi desconectado, reintentando... (ESP8266)");
    if (!wifiConnect()) {
      telnetLog("❌ No se pudo reconectar WiFi (ESP8266)");
      return;
    }
  }
  
  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_GET_ACTIVE_RESERVATIONS;
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(15000);
  
  int statusCode = http.GET();
  String response = (statusCode > 0) ? http.getString() : "";
  http.end();
  
  if (statusCode != 200) {
    telnetLog("❌ Error en sincronización - Status: " + String(statusCode) + " (ESP8266)");
    return;
  }
  
  StaticJsonDocument<2048> doc;
  DeserializationError error = deserializeJson(doc, response);
  
  if (error) {
    telnetLog("❌ Error al parsear JSON de reservas: " + String(error.c_str()) + " (ESP8266)");
    return;
  }
  
  if (!doc["success"].as<bool>()) {
    telnetLog("❌ Respuesta del servidor indica error (ESP8266)");
    return;
  }
  
  // limpiar reservas actuales
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
      
      telnetLog("✅ Reserva cargada - ID: " + reservationId + 
                    " | Plaza: " + String(spotNumber) + 
                    " | Código: " + userCode + 
                    " | Estado: " + status);
      index++;
    }
  }
  
  telnetLog("🔄 Sincronización completada. Reservas cargadas: " + String(index) + " (ESP8266)");
  mostrarEstadosReservas();
}

void webCodigo() {
  if (!server.hasArg("code")) {
    server.send(200, "text/html", generateResultHTML("Error", "Falta código", true));
    return;
  }
  
  String code = server.arg("code");

  StaticJsonDocument<128> j;
  j["code"] = code;
  String payload;
  serializeJson(j, payload);

  WiFiClient client;
  HTTPClient http;
  String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CHECKCODE;
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  int statusCode = http.POST(payload);
  String resp = (statusCode > 0) ? http.getString() : "";
  http.end();

  if (statusCode <= 0) {
    server.send(200, "text/html", generateResultHTML("Error", "No se pudo conectar con el servidor", true));
    return;
  }

  StaticJsonDocument<256> res;
  DeserializationError err = deserializeJson(res, resp);
  if (err) {
    server.send(200, "text/html", generateResultHTML("Error", "Error interno del servidor", true));
    return;
  }

  bool allowed = res["allowed"];
  int spotNumber = res.containsKey("spotId") ? res["spotId"].as<int>() : -1;

  if (allowed) {
    if (arduinoConectado) {
      enviarComandoArduino("ABRIR");
    } else {
      telnetLog("⚠️ Arduino desconectado, no se puede abrir barrera (ESP8266)");
    }
    
    // busca reserva activa por código
    for (int i = 0; i < 4; i++) {
      if (activeReservations[i].userCode == code && !activeReservations[i].confirmed) {
        activeReservations[i].startTime = millis(); // Actualizar tiempo de llegada
        telnetLog("✅ Acceso concedido para reserva: " + activeReservations[i].reservationId + " (ESP8266)");
        break;
      }
    }
  }

  String msg = allowed ? "Acceso permitido" : "Código inválido o reserva no activa";
  server.send(200, "text/html", generateResultHTML(allowed ? "Éxito" : "Acceso denegado", msg, !allowed));
}

// --- PÁGINA WEB ---

void webPrincipal() {
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
    ".status-indicator {"
        "position: absolute;"
        "top: 20px;"
        "right: 20px;"
        "width: 12px;"
        "height: 12px;"
        "border-radius: 50%;"
        "background: " + String(arduinoConectado ? "#4caf50" : "#f44336") + ";"
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
        "<div class='status-indicator'></div>"
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
            "<p><strong>📡 Arduino:</strong> " + String(arduinoConectado ? "Conectado ✅" : "Desconectado ❌") + "</p>"
        "</div>"
    "</div>"
    "</body></html>";
  server.send(200, "text/html", html);
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
    "@media (max-width: 480px) {"
        ".container { padding: 30px 20px; }"
        "h3 { font-size: 24px; }"
        ".icon { width: 60px; height: 60px; font-size: 30px; }"
    "}"
    "</style>"
    "</head><body>"
    "<div class='container'>";
  
  html += "<div class='icon " + String(isError ? "icon-error'>✕" : "icon-success'>✓") + "</div>";
  html += "<h3 class='" + String(isError ? "title-error" : "title-success") + "'>" + title + "</h3>";
  html += "<p>" + message + "</p>";
  html += "<button class='btn' onclick=\"window.location.href='/';\">Volver al formulario</button>";
  html += "</div></body></html>";
  
  return html;
}