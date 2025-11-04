// --- Arduino - ParkElite (1.0) ---

#include <Servo.h>
#include <SoftwareSerial.h>

// --- COMUNICACIÓN CON ESP ---
#define LINK_RX_PIN 12
#define LINK_TX_PIN 11
SoftwareSerial link(LINK_RX_PIN, LINK_TX_PIN); // RX - TX

// --- CONFIGURACIÓN ---
#define SERVO_PIN 10

#define ECHO1_PIN 2
#define TRIG1_PIN 3
#define ECHO2_PIN 4
#define TRIG2_PIN 5
#define ECHO3_PIN 6
#define TRIG3_PIN 7
#define ECHO4_PIN 8
#define TRIG4_PIN 9

Servo barrera;

// --- VARIABLES BASE ---
unsigned long tiempoDeteccion[4] = {0, 0, 0, 0};
bool estadoAnterior[4] = {false, false, false, false};
bool ocupacionConfirmada[4] = {false, false, false, false};
const unsigned long TIEMPO_CONFIRMACION = 60000;
const int DISTANCIA_OCUPADO = 5; // cm

bool espConectado = false;
unsigned long ultRespuestaEsp = 0;

const int SENSOR_TO_SPOT[4] = {4, 6, 3, 5};

void setup() {
  Serial.begin(9600);
  Serial.println(F("Arduino ParkElite arrancando..."));

  link.begin(9600);
  delay(50);

  barrera.attach(SERVO_PIN);
  barrera.write(0); // Barrera cerrada

  // --- PINES ---
  pinMode(TRIG1_PIN, OUTPUT); pinMode(ECHO1_PIN, INPUT);
  pinMode(TRIG2_PIN, OUTPUT); pinMode(ECHO2_PIN, INPUT);
  pinMode(TRIG3_PIN, OUTPUT); pinMode(ECHO3_PIN, INPUT);
  pinMode(TRIG4_PIN, OUTPUT); pinMode(ECHO4_PIN, INPUT);
}

void loop() {
  procesarComandosESP();
  verificarOcupacion();
  delay(500);
}

// --- MENSAJES ---
void procesarComandosESP() {
  /*
    ESP8266 → ARDUINO:
    PING, ABRIR, CONSULTAR_OCUPACION, STATUS_REQUEST, RESET_SENSORS

    ARDUINO → ESP8266:
    PONG, BARRERA_ABIERTA, SENSOR_DETECTING:<n>, OCUPACION_CONFIRMADA:<n>,
    LIBERADO:<n>, ESTADO_OCUPACION:<estados>:<plazas>,
    SYSTEM_STATUS:SENSORS_OK:<estados>:BARRIER_OK:1
  */

  if (link.available()) {
    String orden = link.readStringUntil('\n');
    orden.trim();

    if (orden == "ABRIR") {
      abrirBarrera();
      link.println("BARRERA_ABIERTA");
    } 
    else if (orden == "CONSULTAR_OCUPACION") {
      enviarEstadoOcupacion();
    }
    else if (orden == "PING") {
      link.println("PONG");
      espConectado = true;
      ultRespuestaEsp = millis();
    }
    else if (orden == "STATUS_REQUEST") {
      enviarEstadoCompleto();
    }
    else if (orden == "RESET_SENSORS") {
      resetearSensores();
      link.println("SENSORS_RESET_OK");
    }
  }
}

// --- FUNCIONES ---
void abrirBarrera() {
  barrera.write(90); // Abrir
  delay(5000);
  barrera.write(0);  // Cerrar
}

void verificarOcupacion() {
  for (int i = 0; i < 4; i++) {
    int echoPin, trigPin;
    switch (i) {
      case 0: echoPin = ECHO1_PIN; trigPin = TRIG1_PIN; break;
      case 1: echoPin = ECHO2_PIN; trigPin = TRIG2_PIN; break;
      case 2: echoPin = ECHO3_PIN; trigPin = TRIG3_PIN; break;
      case 3: echoPin = ECHO4_PIN; trigPin = TRIG4_PIN; break;
    }
    
    long distancia = distanciaSensor(echoPin, trigPin);
    bool ocupadoAhora = (distancia < DISTANCIA_OCUPADO && distancia > 0);
    
    // Libre -> Ocupado (detección inicial)
    if (ocupadoAhora && !estadoAnterior[i]) {
      tiempoDeteccion[i] = millis();
      ocupacionConfirmada[i] = false;
      link.print("SENSOR_DETECTING:"); link.println(SENSOR_TO_SPOT[i]);
    }
    
    // Ocupado sostenido -> Confirmado
    if (ocupadoAhora && !ocupacionConfirmada[i] && (millis() - tiempoDeteccion[i] >= TIEMPO_CONFIRMACION)) {
      ocupacionConfirmada[i] = true;
      link.print("OCUPACION_CONFIRMADA:"); link.println(SENSOR_TO_SPOT[i]);
    }
    
    // Ocupado -> Libre
    if (!ocupadoAhora && estadoAnterior[i]) {
      ocupacionConfirmada[i] = false;
      tiempoDeteccion[i] = 0;
      link.print("LIBERADO:"); link.println(SENSOR_TO_SPOT[i]);
    }
    
    estadoAnterior[i] = ocupadoAhora;
  }
}

void enviarEstadoOcupacion() {
  String estado = "ESTADO_OCUPACION:";
  for (int i = 0; i < 4; i++) {
    estado += (ocupacionConfirmada[i] ? "1" : "0");
    if (i < 3) estado += ",";
  }
  estado += ":" + String(SENSOR_TO_SPOT[0]) + "," + String(SENSOR_TO_SPOT[1]) + "," + 
            String(SENSOR_TO_SPOT[2]) + "," + String(SENSOR_TO_SPOT[3]);
  link.println(estado);
}

void enviarEstadoCompleto() {
  String status = "SYSTEM_STATUS:SENSORS_OK:";
  for (int i = 0; i < 4; i++) {
    int echoPin, trigPin;
    switch (i) {
      case 0: echoPin = ECHO1_PIN; trigPin = TRIG1_PIN; break;
      case 1: echoPin = ECHO2_PIN; trigPin = TRIG2_PIN; break;
      case 2: echoPin = ECHO3_PIN; trigPin = TRIG3_PIN; break;
      case 3: echoPin = ECHO4_PIN; trigPin = TRIG4_PIN; break;
    }
    long dist = distanciaSensor(echoPin, trigPin);
    bool sensorOk = (dist > 0 && dist < 400); // rango válido
    status += (sensorOk ? "1" : "0");
    if (i < 3) status += ",";
  }
  status += ":BARRIER_OK:1";
  link.println(status);
}

void resetearSensores() {
  for (int i = 0; i < 4; i++) {
    tiempoDeteccion[i] = 0;
    estadoAnterior[i] = false;
    ocupacionConfirmada[i] = false;
  }
}

long distanciaSensor(int echoPin, int trigPin) {
  long duracion, distancia;
  digitalWrite(trigPin, LOW); delayMicroseconds(2);
  digitalWrite(trigPin, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duracion = pulseIn(echoPin, HIGH, 30000); // timeout 30ms
  if (duracion == 0) return 999; // timeout
  
  distancia = duracion * 0.034 / 2;
  return distancia;
}
