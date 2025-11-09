  // --- ESP8266 - ParkElite (1.0) ---

  #include <ESP8266WiFi.h>
  #include <ESP8266HTTPClient.h>
  #include <WiFiClientSecure.h>
  #include <ESP8266WebServer.h>
  #include <ArduinoJson.h>
  #include <SPI.h>
  #include <MFRC522.h>
  #include <SoftwareSerial.h>

  // --- CONFIGURACIÓN ---
  const char* WIFI_SSID         = "LAPTOP ANEXO 1";
  const char* WIFI_PASSWORD     = "Anexo2043";
  const char* API_HOST_DOMAIN   = "parkelite.onrender.com";

  // --- RUTAS API ---
  static const char* ENDPOINT_CHECKHEALTHSERVER = "/api/health-check";
  static const char* ENDPOINT_CHECKCODE = "/api/reservas/checkCode";
  static const char* ENDPOINT_CONFIRM_ARRIVAL = "/api/reservas/confirm-arrival";
  static const char* ENDPOINT_COMPLETE_ARRIVAL = "/api/reservas/complete-arrival";
  static const char* ENDPOINT_CANCEL_RESERVATION = "/api/reservas/cancel-arrival";
  static const char* ENDPOINT_CANCEL_SPECIFIC_RESERVATION = "/api/reservas/cancel";
  static const char* ENDPOINT_GET_ACTIVE_RESERVATIONS = "/api/reservas/active-reservations";
  static const char* ENDPOINT_CHECK_CONFLICTS = "/api/reservas/check-conflicts";

  // --- PINES RFID Y SOFTWARE SERIAL ---
  #define SS_PIN D1
  #define RST_PIN D0

  #define ARD_RX D3
  #define ARD_TX D2

  // --- SERVIDOR WEB, LOGGER, SOFTWARE SERIAL, Y LECTOR RFID ---
  SoftwareSerial espSerial(ARD_RX, ARD_TX, false);
  WiFiServer telnetServer(23);
  WiFiClient telnetClient;
  ESP8266WebServer server(80);
  MFRC522 mfrc522(SS_PIN, RST_PIN);

  // --- RFIDs AUTORIZADOS ---
  const byte uid1[] = {0x03, 0x77, 0xFF, 0x13};
  const byte uid2[] = {0x93, 0x5D, 0x0C, 0x14};

  // --- TIEMPOS ---
  unsigned long ultRFIDCheck = 0;
  unsigned long ultOcupacionPlazaCheck = 0;
  unsigned long ultPing = 0;
  unsigned long ultReservasCheck = 0;
  unsigned long ultExpiracionCheck = 0;

  const unsigned long TIEMPO_CHECK_RFID = 100; // 100 ms
  const unsigned long TIEMPO_PING = 120000; // 2 minutos
  const unsigned long TIEMPO_OBTENER_RESERVAS = 600000; // 10 minutos
  const unsigned long TIEMPO_CHECK_EXPIRADAS = 180000; // 3 minutos
  const unsigned long TIEMPO_REPORTAR_CONFLICTOS = 60000; // 1 minuto

  // --- VARIABLES BASE ---
  struct ActiveReservation {
    String reservationId;
    int spotNumber;
    unsigned long startTime;
    bool confirmed;
    String userCode;
  };

  String logBuffer = "";
  bool telnetReady = false;
  bool arduinoConectado = false;
  bool inicio = false;
  ActiveReservation activeReservations[4];
  bool spotOccupied[4] = {false, false, false, false};
  int spotMapping[4] = {4, 6, 3, 5}; // Plazas
  unsigned long lastOccupancyReport[4] = {0, 0, 0, 0};

  // --- PROTOTIPOS ---
  bool wifiConnect();
  void testServer();
  int httpGetWithRetry(const String& url, String& out);
  void setupWebServer();
  void webPrincipal();
  void webCodigo();
  void RFID();
  bool esUIDValido(byte* uid);
  String generateResultHTML(const String& title, const String& message, bool isError = false);
  void completarLlegada(String reservationId);
  void confirmarLlegada(String reservationId);
  bool cancelarPorNoLlegada(String reservationId);
  void procesarComandosArduino(String message);
  void obtenerReservasActivas();
  void mostrarEstadosReservas();
  void checkReservasExpiradasCanceladas();
  void Arduino();
  int getSpotIndex(int spotNumber);
  void telnetLog(const String &msg);

  void setup() {
    espSerial.begin(9600);
    delay(200);
    
    // --- WIFI ---
    if (!wifiConnect()) { telnetLog("❌ Error al conectar el WiFi"); return; }

    WiFi.setAutoReconnect(true);
    WiFi.persistent(false);

    telnetServer.begin();
    telnetServer.setNoDelay(true);
    telnetReady = true;

    if (logBuffer.length() > 0) {
      telnetLog("=== LOGS PREVIOS ===");
      telnetLog(logBuffer);
      telnetLog("=== FIN LOGS PREVIOS ===");
      logBuffer = "";
    }

    telnetLog("❗ ESP8266 - ParkElite v1.0 iniciando...");

    // --- ARDUINO ---
    unsigned long ultAviso = millis();
    telnetLog("🔌 Conectando con Arduino... (ESP8266)");
    while (!arduinoConectado) {
      handleTelnetClients();
      Arduino();

      if (millis() - ultAviso >= 10000) {
        telnetLog("⏳ Esperando conexión con Arduino... (ESP8266)");
        ultAviso = millis();
      }

      yield();
      delay(50);
    }

    // --- CHECKEAR SI EL SERVIDOR FUNCIONA ---
    testServer();

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
    setupWebServer();
    
    inicio = true;
    telnetLog("✅ Sistema iniciado (ESP8266)");
  }

  void loop() {
    // --- TELNET LOGGER ---
    handleTelnetClients();

    while (inicio) {
      // --- TELNET LOGGER ---
      handleTelnetClients();

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

      if (millis() - ultExpiracionCheck > TIEMPO_CHECK_EXPIRADAS) {
        checkReservasExpiradasCanceladas();
        ultExpiracionCheck = millis();
      }

      for (int i = 0; i < 4; i++) {
        if (spotOccupied[i] && (millis() - lastOccupancyReport[i] > TIEMPO_REPORTAR_CONFLICTOS)) {
          reportSpotConflict(spotMapping[i], true);
          lastOccupancyReport[i] = millis();
        }
      }

      yield();
    }
  }

  // --- FUNCIONES ---

  void telnetLog(const String &msg) {
    String timestamp = "[" + String(millis() / 1000) + "s] ";
    String fullMsg = timestamp + msg;
    
    //espSerial.println(fullMsg);
    
    if (!telnetReady) {
      // Acumular en buffer si telnet no está listo
      logBuffer += fullMsg + "\n";
      return;
    }
    
    // Enviar a todos los clientes telnet conectados
    if (telnetClient && telnetClient.connected()) {
      telnetClient.println(fullMsg);
      telnetClient.flush();
    }
  }

  bool esUIDValido(byte* uid) {
  bool match1 = true, match2 = true;
  for (byte i = 0; i < 4; i++) {
    if (uid[i] != uid1[i]) match1 = false;
    if (uid[i] != uid2[i]) match2 = false;
  }
  return match1 || match2;
}


  void handleTelnetClients() {
    WiFiClient newClient = telnetServer.available();
    if (newClient) {
      if (!telnetClient || !telnetClient.connected()) {
        if (telnetClient) telnetClient.stop();
        telnetClient = newClient;
        telnetLog("== Cliente Telnet conectado ==");
        telnetLog("IP: " + telnetClient.remoteIP().toString());
        telnetLog("Puerto: " + String(telnetClient.remotePort()));
        telnetClient.println("=== ESP8266 ParkElite v1.0 ===");
        telnetClient.println("Conexion establecida");
        telnetClient.println("Estado Arduino: " + String(arduinoConectado ? "Conectado" : "Desconectado"));
        telnetClient.println("WiFi IP: " + WiFi.localIP().toString());
        telnetClient.println("===========================");
      } else {
        newClient.println("Solo se permite una conexion simultanea");
        newClient.stop();
      }
    }

    // Verificar si el cliente actual sigue conectado
    if (telnetClient && !telnetClient.connected()) {
      telnetLog("=== Cliente Telnet desconectado ===");
      telnetClient.stop();
      telnetClient = WiFiClient();
    }
    
    if (telnetClient && telnetClient.connected() && telnetClient.available()) {
      String command = telnetClient.readStringUntil('\n');
      command.trim();
      
      if (command.length() > 0) {
        telnetLog("COMANDO TELNET: " + command);
        
        // Procesar comandos especiales
        if (command == "help") {
          telnetClient.println("Comandos disponibles:");
          telnetClient.println("  help - Mostrar esta ayuda");
          telnetClient.println("  status - Estado del sistema");
          telnetClient.println("  reservas - Mostrar reservas activas");
          telnetClient.println("  update - Actualizar reservas activas");
          telnetClient.println("  reset - Reiniciar ESP8266");
          telnetClient.println("  arduino - Enviar PING a Arduino");
        }
        else if (command == "status") {
          telnetClient.println("=== ESTADO DEL SISTEMA ===");
          telnetClient.println("WiFi: " + String(WiFi.status() == WL_CONNECTED ? "Conectado" : "Desconectado"));
          telnetClient.println("Arduino: " + String(arduinoConectado ? "Conectado" : "Desconectado"));
          telnetClient.println("IP: " + WiFi.localIP().toString());
          telnetClient.println("Uptime: " + String(millis() / 1000) + "s");
        }
        else if (command == "reservas") {
          mostrarEstadosReservas();
        }
        else if (command == "update") {
          obtenerReservasActivas();
        }
        else if (command == "reset") {
          telnetClient.println("Reiniciando ESP8266...");
          telnetClient.flush();
          delay(1000);
          ESP.restart();
        }
        else if (command == "arduino") {
          espSerial.println("PING");
          telnetLog("→ PING manual enviado a Arduino");
        }
      }
    }
  }

  int httpGetWithRetry(const String& url, String& out) {
    WiFiClientSecure client; client.setInsecure();
    client.setTimeout(60000);
    HTTPClient http;

    for (int attempt = 1; attempt <= 3; attempt++) {
      if (!http.begin(client, url)) {
        telnetLog("❌ begin() fallo: " + url);
        return -100;
      }
      http.setTimeout(60000);
      http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);
      http.useHTTP10(true);
      http.setReuse(false);
      http.setUserAgent("ParkElite-ESP8266/1.0");
      http.addHeader("Accept", "application/json");

      int code = http.GET();
      if (code > 0) {
        out = http.getString();
        http.end();
        telnetLog("🌐 GET ok (" + String(code) + ") intento " + String(attempt));
        return code;
      } else {
        telnetLog("⚠️ GET error (" + String(code) + ") intento " + String(attempt));
        http.end();
        delay(500 * attempt);
      }
    }
    return -11;
  }

  void reportSpotConflict(int spotNumber, bool occupied) {
    if (WiFi.status() != WL_CONNECTED) {
      telnetLog("❌ WiFi desconectado al reportar conflicto");
      return;
    }

    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;
    
    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CHECK_CONFLICTS;
    
    StaticJsonDocument<128> doc;
    doc["spotNumber"] = spotNumber;
    doc["occupied"] = occupied;
    
    String payload;
    serializeJson(doc, payload);
    
    if (!http.begin(client, url)) {
      telnetLog("❌ begin() falló en reportSpotConflict");
      return;
    }
    
    http.setTimeout(15000);
    http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Accept", "application/json");
    
    int statusCode = http.POST(payload);
    String response = (statusCode > 0) ? http.getString() : "";
    
    http.end();
    client.stop();
    
    if (statusCode == 200) {
      telnetLog("✅ Conflicto reportado - Plaza " + String(spotNumber) + 
                " (" + String(occupied ? "ocupada" : "libre") + ")");
    } else {
      telnetLog("⚠️ Error al reportar conflicto: " + String(statusCode));
    }
  }

  void testServer() {
    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CHECKHEALTHSERVER;
    String body;
    int code = httpGetWithRetry(url, body);
    telnetLog("🩺 health-check status=" + String(code));
    if (body.length()) telnetLog("↩︎ Body: " + body);
  }



  bool wifiConnect() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    String msg = "🔌 Conectando WiFi (ESP8266)";
    espSerial.print(msg);
    if (telnetReady) telnetLog(msg);
    
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
      delay(500);
      espSerial.print('.');
      if (telnetReady) telnetLog(".");
    }
    
    if (WiFi.status() == WL_CONNECTED) {
      String successMsg = "✅ WiFi conectado (ESP8266)";
      String ipMsg = "💻 IPv4: " + WiFi.localIP().toString();
      
      espSerial.println(successMsg);
      espSerial.println(ipMsg);
      
      if (telnetReady) {
        telnetLog(successMsg);
        telnetLog(ipMsg);
      } else {
        logBuffer += successMsg + "\n" + ipMsg + "\n";
      }
      return true;
    }
    return false;
  }

  // --- EVENTOS ---

  void Arduino() {
    if (millis() - ultPing >= TIEMPO_PING) {
      espSerial.println("PING");
      ultPing = millis();
      //telnetLog("→ PING enviado");
    }

    while (espSerial.available()) {
      String mensaje = espSerial.readStringUntil('\n');
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

    telnetLog("🔌 Arduino: " + String(arduinoConectado ? "Conectado" : "Desconectado"));
    
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
      espSerial.println("ABRIR");
      delay(1000);
    }

    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
  }

  void confirmarLlegada(String reservationId) {
    reservationId.trim();
    if (reservationId.length() == 0) { telnetLog("❌ confirm-arrival: reservationId vacío"); return; }
    if (WiFi.status() != WL_CONNECTED) { telnetLog("❌ WiFi down"); return; }

    telnetLog("📶 RSSI=" + String(WiFi.RSSI()) + " dBm");
    IPAddress ip;
    if (WiFi.hostByName(API_HOST_DOMAIN, ip)) {
      telnetLog("🧭 DNS " + String(API_HOST_DOMAIN) + " -> " + ip.toString());
    } else {
      telnetLog("⚠️ DNS fallo para " + String(API_HOST_DOMAIN));
    }

    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CONFIRM_ARRIVAL + "/" + reservationId;

    const int MAX_TRIES = 2;
    int code = -1000;
    String resp;

    for (int attempt = 1; attempt <= MAX_TRIES; attempt++) {
      telnetLog("💾 freeHeap(before)= " + String(ESP.getFreeHeap()));
      WiFiClientSecure client; 
      client.setInsecure();
      client.setTimeout(25000);

      HTTPClient http;
      if (!http.begin(client, url)) {
        telnetLog("❌ begin() fallo en confirm-arrival (try " + String(attempt) + ")");
        delay(250 * attempt);
        continue;
      }

      http.setTimeout(25000);
      http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);
      http.useHTTP10(true);
      http.setReuse(false);
      http.addHeader("Accept", "application/json");
      http.addHeader("Content-Type", "application/json");
      http.setUserAgent("ParkElite-ESP8266/1.0");

      code = http.POST("{}");
      resp = (code > 0 && code < 500) ? http.getString() : "";
      telnetLog("🚗 confirm-arrival -> " + String(code) + " (" + String(attempt) + "/" + String(MAX_TRIES) + ")"
                + " | id=" + reservationId + " | body=" + resp);
                
      http.end();
      client.stop();
      telnetLog("💾 freeHeap(after)= " + String(ESP.getFreeHeap()));

      if (code >= 200 && code < 300) {
        for (int i = 0; i < 4; i++) {
          if (activeReservations[i].reservationId == reservationId) {
            activeReservations[i].confirmed = false;
            telnetLog("✅ Reserva -> pendiente: " + reservationId);
            break;
          }
        }
        return;
      }

      if (code == -1 && attempt < MAX_TRIES) {
        telnetLog("⚠️ Reintentando en 2s...");
        delay(2000);
      }
    }

    telnetLog("❌ No se pudo confirmar después de " + String(MAX_TRIES) + " intentos");
  }

  void completarLlegada(String reservationId) {
    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;
    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_COMPLETE_ARRIVAL + "/" + reservationId;
    
    StaticJsonDocument<128> doc;
    doc["reservationId"] = reservationId;
    String payload;
    serializeJson(doc, payload);
      
    http.setTimeout(60000);
    http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);
    http.setReuse(false);

    if (!http.begin(client, url)) {
      telnetLog("❌ begin() fallo en completarLlegada");
      return;
    }

    http.addHeader("Content-Type", "application/json");
    http.addHeader("Accept", "application/json");
    http.setUserAgent("ParkElite-ESP8266/1.0");
  
    int statusCode = http.POST(payload);
    http.end();
    
    telnetLog("🚗 Completación de la reserva - Status: " + String(statusCode));
  }

  bool cancelarPorNoLlegada(String reservationId) {
    if (reservationId.length() == 0) {
      telnetLog("❌ reservationId vacío en cancelarPorNoLlegada");
      return false;
    }

    WiFiClientSecure client; 
    client.setInsecure();
    HTTPClient http;

    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CANCEL_RESERVATION + "?reservationId=" + reservationId;
    
    if (!http.begin(client, url)) { 
      telnetLog("❌ begin() falló en cancelarPorNoLlegada"); 
      return false; 
    }

    http.setTimeout(20000);
    http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);
    http.useHTTP10(true);
    http.setReuse(false);
    http.addHeader("Accept", "application/json");
    http.addHeader("Content-Type", "application/json");

    int code = http.POST(""); // POST vacío como query param
    String resp = (code > 0) ? http.getString() : "";
    
    telnetLog("🛑 cancel-arrival -> " + String(code) + " | id=" + reservationId);
    if (resp.length() > 0) {
      telnetLog("📄 Respuesta: " + resp);
    }
    
    http.end();
    client.stop();

    // 404 = éxito
    if (code >= 200 && code < 300) {
      return true;
    } else if (code == 404) {
      telnetLog("ℹ️ Reserva no encontrada (quizás ya cancelada)");
      return true;
    } else if (code == 409) {
      telnetLog("ℹ️ Reserva no está en estado 'confirmado'");
      return true;
    } else if (code == 200 && resp.indexOf("\"allowed\":false") > 0) {
      telnetLog("⏰ Aún dentro del tiempo de gracia (20 min)");
      return false;
    }
    return false;
  }

void checkReservasExpiradasCanceladas() {
  telnetLog("🔄 Chequeando vencidas por no llegada (server decide)...");
  for (int i = 0; i < 4; i++) {
    if (activeReservations[i].reservationId.length() == 0) continue;
    if (activeReservations[i].confirmed) {
      if (cancelarPorNoLlegada(activeReservations[i].reservationId)) {
        telnetLog("⏰ Cancelada por no llegada: " + activeReservations[i].reservationId);
        activeReservations[i] = {};
      } else {
        telnetLog("ℹ️ Aún sin cancelar (dentro de tiempo o error). Reintento luego.");
      }
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

    ARDUINO → ESP8266:
    PONG	Respuesta al PING enviado por ESP, confirma que Arduino está conectado.
    BARRERA_ABIERTA	Confirma que la barrera fue abierta (respuesta al comando ABRIR).
    SENSOR_DETECTING:<n>	Notifica que un sensor detectó un vehículo en la plaza <n>. Estado inicial antes de confirmar ocupación.
    OCUPACION_CONFIRMADA:<n>	Confirma que la plaza <n> está ocupada después del tiempo de confirmación (60s).
    LIBERADO:<n>	Notifica que la plaza <n> se liberó.
    ESTADO_OCUPACION:<estados>:<plazas>	Envía el estado de ocupación de todas las plazas (1 = ocupada, 0 = libre). Incluye correspondencia de IDs de plaza.
    SYSTEM_STATUS:SENSORS_OK:<estados>:BARRIER_OK:1	Estado completo de sensores y barrera. Indica si sensores están funcionando y si barrera está operativa.
    */

    const char* comandos_esp[] = {"PING", "ABRIR", "CONSULTAR_OCUPACION", "STATUS_REQUEST"};
    const size_t N = sizeof(comandos_esp) / sizeof(comandos_esp[0]);
    bool coincide = false;

    for (size_t i = 0; i < N; i++) {
      if (strcmp(message.c_str(), comandos_esp[i]) == 0) {
        coincide = true;
        break;
      }
    }
    
    if (coincide) return;

    if (message == "PONG") {
      arduinoConectado = true;
      ultPing = millis();
      //procesarComandosArduino("STATUS_REQUEST");
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

      reportSpotConflict(spotNumber, true);
      lastOccupancyReport[spotIndex] = millis();
    }
    else if (message.startsWith("LIBERADO:")) {
      int spotNumber = message.substring(9).toInt();
      int spotIndex = getSpotIndex(spotNumber);
      if (spotIndex >= 0) {
        spotOccupied[spotIndex] = false;
        telnetLog("🅿️ Plaza " + String(spotNumber) + " liberada");

        reportSpotConflict(spotNumber, false);
        lastOccupancyReport[spotIndex] = millis();
        
        // Limpiar reserva confirmada
        for (int i = 0; i < 4; i++) {
          if (activeReservations[i].spotNumber == spotNumber && !activeReservations[i].confirmed) {
            String id_reserva_local = activeReservations[i].reservationId;
            telnetLog("ℹ️ Limpiando reserva completada: " + activeReservations[i].reservationId);
            activeReservations[i].reservationId = "";
            activeReservations[i].spotNumber = -1;
            activeReservations[i].startTime = 0;
            activeReservations[i].confirmed = false;
            activeReservations[i].userCode = "";
            completarLlegada(id_reserva_local);
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
    
    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;
    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_GET_ACTIVE_RESERVATIONS;
    
    http.setTimeout(15000);
    http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);

    if (!http.begin(client, url)) {
      telnetLog("❌ begin() fallo en obtenerReservasActivas");
      return;
    }
    
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Accept", "application/json");
    
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
    
    int codeInt = server.arg("code").toInt();
    String codeNorm = String(codeInt);

    StaticJsonDocument<128> j;
    j["code"] = codeInt;
    String payload;
    serializeJson(j, payload);

    String url = String("https://") + API_HOST_DOMAIN + ENDPOINT_CHECKCODE;
    
    bool allowed = false;
    String serverReservationId = "";
    int spotNumber = -1;
    
    {
      WiFiClientSecure client;
      client.setInsecure();
      HTTPClient http;

      http.setTimeout(15000);
      http.setFollowRedirects(HTTPC_FORCE_FOLLOW_REDIRECTS);

      if (!http.begin(client, url)) {
        telnetLog("❌ begin() fallo en webCodigo");
        server.send(200, "text/html", generateResultHTML("Error", "Error de conexión", true));
        return;
      }

      http.addHeader("Content-Type", "application/json");
      http.addHeader("Accept", "application/json");

      int statusCode = http.POST(payload);
      String resp = (statusCode > 0) ? http.getString() : "";
      
      telnetLog("🔐 POST checkCode -> " + String(statusCode));

      if (statusCode <= 0) {
        http.end();
        server.send(200, "text/html", generateResultHTML("Error", "No se pudo conectar", true));
        return;
      }

      StaticJsonDocument<256> res;
      DeserializationError err = deserializeJson(res, resp);
      
      http.end();
      
      if (err) {
        server.send(200, "text/html", generateResultHTML("Error", "Error del servidor", true));
        return;
      }

      allowed = res["allowed"];
      spotNumber = res.containsKey("spotId") ? res["spotId"].as<int>() : -1;
      serverReservationId = res.containsKey("reservationId") ? String((const char*)res["reservationId"]) : "";
    }
    
    yield();
    delay(100);
    
    telnetLog("💾 Heap antes de confirmar: " + String(ESP.getFreeHeap()));
    
    bool matched = false;

    if (allowed) {
      
      for (int i = 0; i < 4; i++) {
        if (activeReservations[i].reservationId == serverReservationId) {
          if (activeReservations[i].confirmed) {
            matched = true;
            activeReservations[i].startTime = millis();
            confirmarLlegada(activeReservations[i].reservationId);
          } else {
            telnetLog("ℹ️ Reserva no confirmada: " + activeReservations[i].reservationId);
          }
          break;
        }
      }

      if (!matched) {
        telnetLog("❌ Código válido pero no en activeReservations: " + codeNorm);
      }
    }

    if (allowed && matched) {
      espSerial.println("ABRIR");
      //espSerial.flush();
    }

    String msg = allowed ? "Acceso permitido" : "Código inválido";
    msg = matched ? msg : "Acceso denegado";
    server.send(200, "text/html", generateResultHTML((allowed && matched) ? "Éxito" : "Denegado", msg, (!allowed || !matched)));
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
    const char* redirectTo = "/";
    const int countdownSec = 5;

    String html = "<html><head>"
      "<meta charset='UTF-8'>"
      "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
      "<style>"
      "*{margin:0;padding:0;box-sizing:border-box}"
      "body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;"
        "background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;"
        "display:flex;align-items:center;justify-content:center;padding:20px}"
      ".container{background:rgba(255,255,255,.95);backdrop-filter:blur(10px);border-radius:20px;"
        "padding:40px 30px;box-shadow:0 20px 40px rgba(0,0,0,.1);max-width:500px;width:100%;"
        "text-align:center;border:1px solid rgba(255,255,255,.2)}"
      ".icon{width:80px;height:80px;margin:0 auto 20px;border-radius:50%;display:flex;"
        "align-items:center;justify-content:center;font-size:40px;font-weight:bold}"
      ".icon-success{background:linear-gradient(135deg,#4facfe 0%,#00f2fe 100%);color:#fff}"
      ".icon-error{background:linear-gradient(135deg,#ff6b6b 0%,#ffa500 100%);color:#fff}"
      "h3{font-size:28px;margin-bottom:15px;font-weight:600}"
      ".title-success{color:#2d5a87}.title-error{color:#c53030}"
      "p{font-size:16px;line-height:1.6;margin-bottom:22px;color:#4a5568}"
      ".btn{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border:none;"
        "padding:14px 26px;border-radius:50px;font-size:16px;font-weight:600;cursor:pointer;"
        "transition:.3s;box-shadow:0 4px 15px rgba(102,126,234,.4);text-decoration:none;display:inline-block}"
      ".btn:hover{transform:translateY(-2px);box-shadow:0 8px 25px rgba(102,126,234,.6)}"
      ".count-wrap{margin:8px 0 18px}"
      ".badge{display:inline-block;background:#edf2f7;color:#2d3748;border-radius:9999px;"
        "padding:8px 14px;font-weight:700;letter-spacing:.5px}"
      ".progress{height:8px;background:#e2e8f0;border-radius:9999px;overflow:hidden;margin-top:12px}"
      ".bar{display:block;height:100%;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);width:100%;"
        "animation:shrink 5s linear forwards}"
      "@keyframes shrink{from{width:100%}to{width:0%}}"
      "@media(max-width:480px){.container{padding:30px 20px}h3{font-size:24px}.icon{width:60px;height:60px;font-size:30px}}"
      "</style>"
      "</head><body><div class='container'>";

    html += "<div class='icon " + String(isError ? "icon-error'>✕" : "icon-success'>✓") + "</div>";
    html += "<h3 class='" + String(isError ? "title-error" : "title-success") + "'>" + title + "</h3>";
    html += "<p>" + message + "</p>";

    html += "<div class='count-wrap'>"
              "<span class='badge'>Volviendo en <span id='count'>" + String(countdownSec) + "</span> s…</span>"
              "<div class='progress'><span class='bar'></span></div>"
            "</div>";

    html += "<button class='btn' onclick=\"window.location.href='" + String(redirectTo) + "'\">Volver ahora</button>"
            "</div>";

    html += "<script>"
            "var t=" + String(countdownSec) + ";"
            "var el=document.getElementById('count');"
            "var iv=setInterval(function(){t--; if(el) el.textContent=t; if(t<=0){clearInterval(iv);location.href='" + String(redirectTo) + "'}},1000);"
            "</script>";

    html += "</body></html>";
    return html;
  }