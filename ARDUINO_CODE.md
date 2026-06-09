# 💻 Dokumentasi Kode Arduino/ESP32 — Flood Detection Warning System

## Library yang Dibutuhkan

Install semua library berikut melalui **Arduino IDE → Library Manager** (`Ctrl+Shift+I`):

| Library | Versi | Fungsi |
|---------|-------|--------|
| `Firebase ESP32 Client` | ≥ 4.x | Koneksi ke Firebase |
| `NewPing` | ≥ 1.9 | Sensor ultrasonik HC-SR04 |

Tambahkan board ESP32 melalui **Board Manager**:
```
URL: https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

---

## Struktur File

```
firmware/
├── flood_detection.ino    # Program utama
└── config.h               # Konfigurasi (WiFi, Firebase, pin, threshold)
```

---

## `config.h` — File Konfigurasi

```cpp
#ifndef CONFIG_H
#define CONFIG_H

// ===== WiFi =====
#define WIFI_SSID       "nama_wifi_kamu"
#define WIFI_PASSWORD   "password_wifi_kamu"

// ===== Firebase =====
#define FIREBASE_HOST   "https://nama-project-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH   "database_secret_atau_api_key"

// ===== Pin Definitions =====
#define TRIG_PIN        5
#define ECHO_PIN        18
#define LED_HIJAU       25
#define LED_KUNING      26
#define LED_MERAH       27
#define BUZZER_PIN      14

// ===== LoRa Pin =====
#define LORA_SCK        18
#define LORA_MISO       19
#define LORA_MOSI       23
#define LORA_SS         5
#define LORA_RST        4
#define LORA_DIO0       2

// ===== Threshold Jarak (cm) =====
// Jarak diukur dari sensor ke permukaan air
// Semakin kecil jarak = air semakin tinggi
#define JARAK_AMAN      150   // > 150 cm = Aman
#define JARAK_SIAGA     80    // 80–150 cm = Siaga
                              // < 80 cm   = Evakuasi

// ===== Interval Pengiriman Data (ms) =====
#define INTERVAL_KIRIM  5000  // kirim data setiap 5 detik

#endif
```

---

## `flood_detection.ino` — Program Utama

```cpp
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <NewPing.h>
#include "config.h"

// ===== Objek Firebase =====
FirebaseData fbData;
FirebaseAuth auth;
FirebaseConfig config;

// ===== Objek Sensor =====
NewPing sonar(TRIG_PIN, ECHO_PIN, 400); // max distance 400 cm

// ===== Variabel Global =====
unsigned long lastSendTime = 0;
String statusBanjir = "";
float jarakCm = 0;

// ============================================================
void setup() {
  Serial.begin(115200);

  // Setup pin
  pinMode(LED_HIJAU,  OUTPUT);
  pinMode(LED_KUNING, OUTPUT);
  pinMode(LED_MERAH,  OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  matikanSemuaLED();
  digitalWrite(BUZZER_PIN, LOW);

  // Koneksi WiFi
  Serial.print("Menghubungkan ke WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi terhubung!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  // Konfigurasi Firebase
  config.host      = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Firebase siap.");

  // LoRa telah dihapus pada konfigurasi proyek ini.
}

// ============================================================
void loop() {
  // Baca jarak dari sensor ultrasonik
  jarakCm = bacaJarak();
  Serial.print("Jarak: ");
  Serial.print(jarakCm);
  Serial.println(" cm");

  // Tentukan status banjir
  statusBanjir =enentukanStatus(jarakCm);
  Serial.print("Status: ");
  Serial.println(statusBanjir);

  // Aktifkan LED & Buzzer sesuai status
  aktifkanIndikator(statusBanjir);

  // Kirim data ke Firebase setiap INTERVAL_KIRIM ms
  if (millis() - lastSendTime >= INTERVAL_KIRIM) {
    lastSendTime = millis();
    kirimKeFirebase(jarakCm, statusBanjir);
  }

  delay(1000);
}

// ============================================================
// FUNGSI: Baca jarak dari HC-SR04
// ============================================================
float bacaJarak() {
  unsigned int uS = sonar.ping_median(5); // rata-rata 5 ping
  float jarak = uS / US_ROUNDTRIP_CM;
  if (jarak == 0) jarak = 999; // jika tidak terdeteksi
  return jarak;
}

// ============================================================
// FUNGSI: Tentukan status berdasarkan jarak
// ============================================================
String nentukanStatus(float jarak) {
  if (jarak > JARAK_AMAN) {
    return "AMAN";
  } else if (jarak > JARAK_SIAGA) {
    return "SIAGA";
  } else {
    return "EVAKUASI";
  }
}

// ============================================================
// FUNGSI: Kontrol LED & Buzzer
// ============================================================
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
    // Tidak ada buzzer

  } else if (status == "SIAGA") {
    digitalWrite(LED_KUNING, HIGH);
    // Buzzer beep lambat
    tone(BUZZER_PIN, 1000, 200);
    delay(700);

  } else if (status == "EVAKUASI") {
    digitalWrite(LED_MERAH, HIGH);
    // Buzzer beep cepat berulang
    for (int i = 0; i < 3; i++) {
      tone(BUZZER_PIN, 2000, 150);
      delay(300);
    }
  }
}

// ============================================================
// FUNGSI: Kirim data ke Firebase Realtime Database
// ============================================================
void kirimKeFirebase(float jarak, String status) {
  if (Firebase.ready()) {
    // Timestamp (gunakan millis sebagai pengganti jika tanpa RTC)
    unsigned long ts = millis();

    // Simpan data terkini
    Firebase.setFloat(fbData,  "/sensor/jarak_cm", jarak);
    Firebase.setString(fbData, "/sensor/status",   status);
    Firebase.setInt(fbData,    "/sensor/timestamp", ts);

    // Simpan ke riwayat (history)
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

// ============================================================
// FUNGSI: Kirim data via LoRa
// ============================================================
void kirimLoRa(float jarak, String status) {
  String pesan = "JARAK:" + String(jarak) + ",STATUS:" + status;

  LoRa.beginPacket();
  LoRa.print(pesan);
  LoRa.endPacket();

  Serial.print("LoRa dikirim: ");
  Serial.println(pesan);
}
```

---

## Alur Program (Flowchart)

```
[START]
   |
[Setup: WiFi, Firebase, LoRa, Pin]
   |
[LOOP]
   |
[Baca Jarak HC-SR04]
   |
[Tentukan Status]
   |---> Jarak > 150cm  --> STATUS: AMAN     --> LED Hijau
   |---> 80–150cm       --> STATUS: SIAGA    --> LED Kuning + Buzzer Lambat
   |---> Jarak < 80cm   --> STATUS: EVAKUASI --> LED Merah + Buzzer Cepat
   |
[Apakah sudah 5 detik?]
   |-- YA --> Kirim ke Firebase + Kirim via LoRa
   |-- TIDAK --> Lanjut loop
   |
[Delay 1 detik --> Ulangi LOOP]
```

---

## Tips & Troubleshooting

| Masalah | Kemungkinan Penyebab | Solusi |
|---------|----------------------|--------|
| Jarak selalu 999 | Sensor tidak terdeteksi | Cek kabel VCC/GND/TRIG/ECHO |
| Firebase gagal koneksi | WiFi belum terhubung | Pastikan SSID & password benar |
| ESP32 restart terus | Brownout / tegangan kurang | Pastikan sumber daya stabil |
| LoRa gagal init | Pin konflik atau VCC salah | LoRa harus 3.3V, bukan 5V |
| LED tidak menyala | Resistor terbalik / pin salah | Cek polaritas LED dan nomor GPIO |

---

## Catatan Pengembangan

- Tambahkan modul **RTC DS3231** untuk timestamp yang akurat (bukan `millis()`)
- Tambahkan **deep sleep** pada ESP32 untuk menghemat daya baterai
- Kalibrasi nilai `JARAK_AMAN` dan `JARAK_SIAGA` sesuai kondisi lapangan sebenarnya
