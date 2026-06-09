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
#define JARAK_AMAN      150   // > 150 cm = Aman
#define JARAK_SIAGA     80    // 80–150 cm = Siaga
                              // < 80 cm   = Evakuasi

// ===== Interval Pengiriman Data (ms) =====
#define INTERVAL_KIRIM  5000  // kirim data setiap 5 detik

#endif
