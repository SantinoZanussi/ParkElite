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
unsigned long tiempoDeteccion[4] = {0, 0, 0, 0}; // Tiempo cuando se detectó ocupación en cada sensor
bool estadoAnterior[4] = {false, false, false, false}; // Estado anterior de cada sensor
bool ocupacionConfirmada[4] = {false, false, false, false}; // Si ya se confirmó la ocupación
const unsigned long TIEMPO_CONFIRMACION = 60000; // 1 minuto en milisegundos
const int DISTANCIA_OCUPADO = 20; // Distancia en cm para considerar ocupado

void setup() {
  Serial.begin(9600);
  espSerial.begin(9600);
  barrera.attach(SERVO_PIN);
  barrera.write(0); // Barrera cerrada

  //pines sensores ultrasónicos
  pinMode(TRIG1_PIN, OUTPUT);
  pinMode(ECHO1_PIN, INPUT);
  
  pinMode(TRIG2_PIN, OUTPUT);
  pinMode(ECHO2_PIN, INPUT);
  
  pinMode(TRIG3_PIN, OUTPUT);
  pinMode(ECHO3_PIN, INPUT);
  
  pinMode(TRIG4_PIN, OUTPUT);
  pinMode(ECHO4_PIN, INPUT);

  Serial.println("Listo. Esperando orden...");
}

void loop() {
  // Leer si llega orden del ESP
  if (espSerial.available()) {
    String orden = espSerial.readStringUntil('\n');
    orden.trim();
    Serial.println("ESP → " + orden);
    if (orden == "ABRIR") {
      abrirBarrera();
    } else if (orden == "CONSULTAR_OCUPACION") {
      enviarEstadoOcupacion();
    }
  }

  // Verificar ocupación en cada sensor
  verificarOcupacion();
  
  delay(500); // Reducido para mejor responsividad
}

void abrirBarrera() {
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
      Serial.print("SENSOR_");
      Serial.print(i + 1);
      Serial.println("_DETECTANDO");
    }
    
    // Si está ocupado y ha pasado el tiempo de confirmación
    if (ocupadoAhora && !ocupacionConfirmada[i] && 
        (millis() - tiempoDeteccion[i] >= TIEMPO_CONFIRMACION)) {
      ocupacionConfirmada[i] = true;
      Serial.print("OCUPACION_CONFIRMADA_");
      Serial.println(i + 1); // Envía número de plaza (1-4)
    }
    
    // Si cambió de ocupado a libre
    if (!ocupadoAhora && estadoAnterior[i]) {
      ocupacionConfirmada[i] = false;
      tiempoDeteccion[i] = 0;
      Serial.print("LIBERADO_");
      Serial.println(i + 1);
    }
    
    estadoAnterior[i] = ocupadoAhora;
  }
}

void enviarEstadoOcupacion() {
  espSerial.print("ESTADO_OCUPACION:");
  for (int i = 0; i < 4; i++) {
    espSerial.print(ocupacionConfirmada[i] ? "1" : "0");
    if (i < 3) Serial.print(",");
  }
  espSerial.println();
  Serial.println("→ Enviado a ESP: ESTADO_OCUPACION");
}

bool detectarAuto() {
  return (distanciaSensor(ECHO1_PIN, TRIG1_PIN) < DISTANCIA_OCUPADO) ||
         (distanciaSensor(ECHO2_PIN, TRIG2_PIN) < DISTANCIA_OCUPADO) ||
         (distanciaSensor(ECHO3_PIN, TRIG3_PIN) < DISTANCIA_OCUPADO) ||
         (distanciaSensor(ECHO4_PIN, TRIG4_PIN) < DISTANCIA_OCUPADO);
}

// Función para medir distancia en cm de un sensor ultrasónico
long distanciaSensor(int echoPin, int trigPin) {
  long duracion, distancia;

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duracion = pulseIn(echoPin, HIGH, 30000); // timeout 30ms para evitar bloqueo
  if (duracion == 0) return 999; // Si timeout devuelve un valor grande (no detectado)
  
  distancia = duracion * 0.034 / 2;
  return distancia;
}