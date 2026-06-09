#include <WiFi.h>
#include <FirebaseESP32.h>
#include <NewPing.h>
#include <SPI.h>
#include <LoRa.h>
#include "config.h"

FirebaseData fbData;
FirebaseAuth auth;
FirebaseConfig config;

NewPing sonar(TRIG_PIN, ECHO_PIN, 400);

unsigned long lastSendTime = 0;
String statusBanjir = "";
float jarakCm = 0;

void setup() {
  Serial.begin(115200);

  pinMode(LED_HIJAU,  OUTPUT);
  pinMode(LED_KUNING, OUTPUT);
  pinMode(LED_MERAH,  OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  matikanSemuaLED();
  digitalWrite(BUZZER_PIN, LOW);

  Serial.print("Menghubungkan ke WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi terhubung!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  config.host      = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Firebase siap.");

  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_SS);
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(433E6)) {
    Serial.println("LoRa gagal diinisialisasi!");
  } else {
    Serial.println("LoRa siap.");
  }
}

void loop() {
  jarakCm = bacaJarak();
  Serial.print("Jarak: ");
  Serial.print(jarakCm);
  Serial.println(" cm");

  statusBanjir = tentukanStatus(jarakCm);
  Serial.print("Status: ");
  Serial.println(statusBanjir);

  aktifkanIndikator(statusBanjir);

  if (millis() - lastSendTime >= INTERVAL_KIRIM) {
    lastSendTime = millis();
    kirimKeFirebase(jarakCm, statusBanjir);
    kirimLoRa(jarakCm, statusBanjir);
  }

  delay(1000);
}

float bacaJarak() {
  unsigned int uS = sonar.ping_median(5);
  float jarak = uS / US_ROUNDTRIP_CM;
  if (jarak == 0) jarak = 999;
  return jarak;
}

String tentukanStatus(float jarak) {
  if (jarak > JARAK_AMAN) {
    return "AMAN";
  } else if (jarak > JARAK_SIAGA) {
    return "SIAGA";
  } else {
    return "EVAKUASI";
  }
}

void matikanSemuaLED() {
  digitalWrite(LED_HIJAU,  LOW);
  digitalWrite(LED_KUNING, LOW);
  digitalWrite(LED_MERAH,  LOW);
}

void aktifkanIndikator(String status) {
  matikanSemuaLED();
  noTone(BUZZER_PIN);

  if (status == "AMAN") {
    digitalWrite(LED_HIJAU, HIGH);
  } else if (status == "SIAGA") {
    digitalWrite(LED_KUNING, HIGH);
    tone(BUZZER_PIN, 1000, 200);
    delay(700);
  } else if (status == "EVAKUASI") {
    digitalWrite(LED_MERAH, HIGH);
    for (int i = 0; i < 3; i++) {
      tone(BUZZER_PIN, 2000, 150);
      delay(300);
    }
  }
}

void kirimKeFirebase(float jarak, String status) {
  if (Firebase.ready()) {
    unsigned long ts = millis();

    Firebase.setFloat(fbData,  "/sensor/jarak_cm", jarak);
    Firebase.setString(fbData, "/sensor/status",   status);
    Firebase.setInt(fbData,    "/sensor/timestamp", ts);

    String path = "/history/" + String(ts);
    FirebaseJson json;
    json.set("jarak_cm", jarak);
    json.set("status",   status);
    json.set("timestamp", (int)ts);
    Firebase.setJSON(fbData, path, json);

    Serial.println("Data terkirim ke Firebase.");
  } else {
    Serial.println("Firebase tidak siap.");
  }
}

void kirimLoRa(float jarak, String status) {
  String pesan = "JARAK:" + String(jarak) + ",STATUS:" + status;

  LoRa.beginPacket();
  LoRa.print(pesan);
  LoRa.endPacket();

  Serial.print("LoRa dikirim: ");
  Serial.println(pesan);
}
