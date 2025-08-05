#include <Servo.h> 
#include <SoftwareSerial.h>

SoftwareSerial espSerial(0, 1); // RX, TX hacia el ESP8266

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

// Variables para control de ocupación
unsigned long tiempoDeteccion[4] = {0, 0, 0, 0};
bool estadoAnterior[4] = {false, false, false, false};
bool ocupacionConfirmada[4] = {false, false, false, false};
const unsigned long TIEMPO_CONFIRMACION = 60000; // 1 minuto
const int DISTANCIA_OCUPADO = 20; // cm

// Variables para heartbeat y comunicación
unsigned long lastHeartbeat = 0;
const unsigned long HEARTBEAT_INTERVAL = 30000; // 30 segundos
bool espConnected = false;
unsigned long lastEspResponse = 0;

// Mapeo de sensores físicos a plazas de BD
const int SENSOR_TO_SPOT[4] = {3, 4, 5, 6}; // Sensor 0->Plaza 3, etc.

void setup() {
  Serial.begin(9600);
  espSerial.begin(9600);
  barrera.attach(SERVO_PIN);
  barrera.write(0); // Barrera cerrada

  // Configurar pines sensores
  pinMode(TRIG1_PIN, OUTPUT);
  pinMode(ECHO1_PIN, INPUT);
  pinMode(TRIG2_PIN, OUTPUT);
  pinMode(ECHO2_PIN, INPUT);
  pinMode(TRIG3_PIN, OUTPUT);
  pinMode(ECHO3_PIN, INPUT);
  pinMode(TRIG4_PIN, OUTPUT);
  pinMode(ECHO4_PIN, INPUT);

  Serial.println("Arduino iniciado. Esperando ESP8266...");
  
  // Enviar estado inicial después de un breve delay
  delay(3000);
  enviarEstadoInicial();
}

void loop() {
  procesarComandosESP();
  verificarOcupacion();
  enviarHeartbeat();
  
  delay(500);
}

void procesarComandosESP() {
  if (espSerial.available()) {
    String orden = espSerial.readStringUntil('\n');
    orden.trim();
    Serial.println("ESP → " + orden);
    
    if (orden == "ABRIR") {
      abrirBarrera();
      espSerial.println("BARRERA_ABIERTA");
    } 
    else if (orden == "CONSULTAR_OCUPACION") {
      enviarEstadoOcupacion();
    }
    else if (orden == "PING") {
      espSerial.println("PONG");
      espConnected = true;
      lastEspResponse = millis();
    }
    else if (orden == "STATUS_REQUEST") {
      enviarEstadoCompleto();
    }
    else if (orden == "RESET_SENSORS") {
      resetearSensores();
    }
  }
}

void abrirBarrera() {
  Serial.println("Abriendo barrera...");
  barrera.write(90); // Abrir
  delay(5000);       // Tiempo para pasar
  barrera.write(0);  // Cerrar
  Serial.println("Barrera cerrada");
}

void verificarOcupacion() {
  for (int i = 0; i < 4; i++) {
    int echoPin, trigPin;
    
    // Asignar pines según el sensor
    switch (i) {
      case 0: echoPin = ECHO1_PIN; trigPin = TRIG1_PIN; break;
      case 1: echoPin = ECHO2_PIN; trigPin = TRIG2_PIN; break;
      case 2: echoPin = ECHO3_PIN; trigPin = TRIG3_PIN; break;
      case 3: echoPin = ECHO4_PIN; trigPin = TRIG4_PIN; break;
    }
    
    long distancia = distanciaSensor(echoPin, trigPin);
    bool ocupadoAhora = (distancia < DISTANCIA_OCUPADO && distancia > 0);
    
    // Si cambió el estado de libre a ocupado
    if (ocupadoAhora && !estadoAnterior[i]) {
      tiempoDeteccion[i] = millis();
      ocupacionConfirmada[i] = false;
      
      // Enviar detección inmediata al ESP
      String msg = "SENSOR_DETECTING:" + String(SENSOR_TO_SPOT[i]);
      espSerial.println(msg);
      Serial.println("Detectando en plaza " + String(SENSOR_TO_SPOT[i]));
    }
    
    // Si está ocupado y ha pasado el tiempo de confirmación
    if (ocupadoAhora && !ocupacionConfirmada[i] && 
        (millis() - tiempoDeteccion[i] >= TIEMPO_CONFIRMACION)) {
      ocupacionConfirmada[i] = true;
      
      // Enviar confirmación al ESP con número de plaza de BD
      String msg = "OCUPACION_CONFIRMADA:" + String(SENSOR_TO_SPOT[i]);
      espSerial.println(msg);
      Serial.println("Ocupación confirmada en plaza " + String(SENSOR_TO_SPOT[i]));
    }
    
    // Si cambió de ocupado a libre
    if (!ocupadoAhora && estadoAnterior[i]) {
      ocupacionConfirmada[i] = false;
      tiempoDeteccion[i] = 0;
      
      // Enviar liberación al ESP
      String msg = "LIBERADO:" + String(SENSOR_TO_SPOT[i]);
      espSerial.println(msg);
      Serial.println("Plaza " + String(SENSOR_TO_SPOT[i]) + " liberada");
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
  
  espSerial.println(estado);
  Serial.println("Estado enviado al ESP: " + estado);
}

void enviarEstadoInicial() {
  Serial.println("Enviando estado inicial al ESP8266...");
  espSerial.println("ARDUINO_READY");
  delay(1000);
  enviarEstadoOcupacion();
  delay(500);
  enviarEstadoCompleto();
}

void enviarEstadoCompleto() {
  String status = "SYSTEM_STATUS:";
  status += "SENSORS_OK:";
  
  // Verificar cada sensor
  for (int i = 0; i < 4; i++) {
    int echoPin, trigPin;
    switch (i) {
      case 0: echoPin = ECHO1_PIN; trigPin = TRIG1_PIN; break;
      case 1: echoPin = ECHO2_PIN; trigPin = TRIG2_PIN; break;
      case 2: echoPin = ECHO3_PIN; trigPin = TRIG3_PIN; break;
      case 3: echoPin = ECHO4_PIN; trigPin = TRIG4_PIN; break;
    }
    
    long dist = distanciaSensor(echoPin, trigPin);
    bool sensorOk = (dist > 0 && dist < 400); // Rango válido
    status += (sensorOk ? "1" : "0");
    if (i < 3) status += ",";
  }
  
  status += ":BARRIER_OK:1"; // Asumir barrera OK
  espSerial.println(status);
  Serial.println("Estado completo enviado");
}

void resetearSensores() {
  Serial.println("Reseteando sensores...");
  for (int i = 0; i < 4; i++) {
    tiempoDeteccion[i] = 0;
    estadoAnterior[i] = false;
    ocupacionConfirmada[i] = false;
  }
  espSerial.println("SENSORS_RESET_OK");
  Serial.println("Sensores reseteados");
}

void enviarHeartbeat() {
  if (millis() - lastHeartbeat > HEARTBEAT_INTERVAL) {
    espSerial.println("HEARTBEAT:" + String(millis()));
    Serial.println("Heartbeat enviado");
    lastHeartbeat = millis();
    
    // Si no hay respuesta del ESP en mucho tiempo
    if (millis() - lastEspResponse > 60000) {
      espConnected = false;
      Serial.println("⚠️ ESP8266 no responde");
    }
  }
}

long distanciaSensor(int echoPin, int trigPin) {
  long duracion, distancia;

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duracion = pulseIn(echoPin, HIGH, 30000); // timeout 30ms
  if (duracion == 0) return 999; // timeout
  
  distancia = duracion * 0.034 / 2;
  return distancia;
}