// --- Arduino - ParkElite (1.0) ---

#include <Servo.h> 

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
  barrera.attach(SERVO_PIN);
  barrera.write(0); // Barrera cerrada

  // --- PINES ---
  pinMode(TRIG1_PIN, OUTPUT);
  pinMode(ECHO1_PIN, INPUT);
  pinMode(TRIG2_PIN, OUTPUT);
  pinMode(ECHO2_PIN, INPUT);
  pinMode(TRIG3_PIN, OUTPUT);
  pinMode(ECHO3_PIN, INPUT);
  pinMode(TRIG4_PIN, OUTPUT);
  pinMode(ECHO4_PIN, INPUT);
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

  if (Serial.available()) {
    String orden = Serial.readStringUntil('\n');
    orden.trim();
    //Serial.println("ESP → " + orden);
    
    if (orden == "ABRIR") {
      abrirBarrera();
      Serial.println("BARRERA_ABIERTA");
    } 
    else if (orden == "CONSULTAR_OCUPACION") {
      enviarEstadoOcupacion();
    }
    else if (orden == "PING") {
      Serial.println("PONG");
      espConectado = true;
      ultRespuestaEsp = millis();
    }
    else if (orden == "STATUS_REQUEST") {
      enviarEstadoCompleto();
    }
    else if (orden == "RESET_SENSORS") {
      resetearSensores();
    }
  }
}

// --- FUNCIONES ---
void abrirBarrera() {
  //Serial.println("Abriendo barrera...");
  barrera.write(90); // Abrir
  delay(5000);
  barrera.write(0);  // Cerrar
  //Serial.println("Barrera cerrada");
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
    
    // Si cambió el estado de libre a ocupado
    if (ocupadoAhora && !estadoAnterior[i]) {
      tiempoDeteccion[i] = millis();
      ocupacionConfirmada[i] = false;
      
      String msg = "SENSOR_DETECTING:" + String(SENSOR_TO_SPOT[i]);
      Serial.println(msg);
      //Serial.println("Detectando en plaza " + String(SENSOR_TO_SPOT[i]));
    }
    
    // Si está ocupado y ha pasado el tiempo de confirmación
    if (ocupadoAhora && !ocupacionConfirmada[i] && 
        (millis() - tiempoDeteccion[i] >= TIEMPO_CONFIRMACION)) {
      ocupacionConfirmada[i] = true;
      
      String msg = "OCUPACION_CONFIRMADA:" + String(SENSOR_TO_SPOT[i]);
      Serial.println(msg);
      //Serial.println("Ocupación confirmada en plaza " + String(SENSOR_TO_SPOT[i]));
    }
    
    // Si cambió de ocupado a libre
    if (!ocupadoAhora && estadoAnterior[i]) {
      ocupacionConfirmada[i] = false;
      tiempoDeteccion[i] = 0;
      
      String msg = "LIBERADO:" + String(SENSOR_TO_SPOT[i]);
      Serial.println(msg);
      //Serial.println("Plaza " + String(SENSOR_TO_SPOT[i]) + " liberada");
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
  
  Serial.println(estado);
  //Serial.println("Estado enviado al ESP: " + estado);
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
  Serial.println(status);
  //Serial.println("Estado completo enviado");
}

void resetearSensores() {
  //Serial.println("Reseteando sensores...");
  for (int i = 0; i < 4; i++) {
    tiempoDeteccion[i] = 0;
    estadoAnterior[i] = false;
    ocupacionConfirmada[i] = false;
  }
  Serial.println("SENSORS_RESET_OK");
  //Serial.println("Sensores reseteados");
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