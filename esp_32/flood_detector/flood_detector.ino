#include <WiFi.h>
#include <HTTPClient.h>

// --- KONFIGURASI PIN ---
#define TRIG_PIN 12      
#define ECHO_PIN 14     
#define LED_GREEN 25     
#define LED_YELLOW 26    
#define LED_RED 27       
#define BUZZER 23        

// --- KONFIGURASI WIFI & SERVER ---
const char* WIFI_SSID = "Pheww";
const char* WIFI_PASS = "belikuotabos";
// PASTIKAN SERVER_URL INI DIGANTI DENGAN URL NGROK BARU ANDA!
const char* SERVER_URL = "https://acclimatisable-loungingly-jaelyn.ngrok-free.dev/data"; 

// --- KONFIGURASI LOGIKA ---
const int SAMPLE_INTERVAL_MS = 20000; // Kirim data tiap 20 detik (3x/menit)
const int WARNING_THRESHOLD_PERCENT = 60; // Batas Siaga: 60% (60 cm)
const int DANGER_THRESHOLD_PERCENT = 85; // Batas Bahaya: 85% (85 cm)

// --- KALIBRASI ULTRASONIC ---
// PENTING: Ketinggian air 100% adalah 100.0 cm (1 meter)
const float SENSOR_MOUNT_HEIGHT_CM = 100.0; 
const float MIN_DISTANCE_CM = 2.0;         
const float MAX_DISTANCE_CM = 400.0;       

// Filter settings
const int NUM_ULTRASONIC_SAMPLES = 5;

// Status & Timing
bool wifiConnected = false;
unsigned long lastSampleTime = 0;

void setup() {
  Serial.begin(9600);
  
  // Setup Pin
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  pinMode(BUZZER, OUTPUT);

  // Reset Output (Matiin semua dulu)
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_YELLOW, LOW);
  digitalWrite(LED_RED, LOW);
  digitalWrite(BUZZER, LOW);

  Serial.println("\n=== Flood Detection System (Ultrasonic + WiFi) ===");
  
  // Koneksi ke WiFi
  connectWiFi();
}

/**
 * @brief Mencoba koneksi ke WiFi. Blocking selama proses.
 */
void connectWiFi() {
  // Hanya jalankan jika belum terhubung
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    return;
  }
  
  Serial.print("Connecting to WiFi");
  WiFi.disconnect(true); // Putuskan koneksi sebelumnya
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  
  int tries = 0;
  // Kita batasi waktu tunggu agar tidak terlalu lama
  while (WiFi.status() != WL_CONNECTED && tries < 40) { // 40 * 500ms = 20 detik
    delay(500);
    Serial.print(".");
    tries++;
    // Kedip Merah pas connecting
    digitalWrite(LED_RED, !digitalRead(LED_RED));
  }
  
  Serial.println();
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.print("Connected! IP: ");
    Serial.println(WiFi.localIP());
    
    // Matikan merah, kedip hijau tanda sukses
    digitalWrite(LED_RED, LOW);
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_GREEN, HIGH); delay(100);
      digitalWrite(LED_GREEN, LOW); delay(100);
    }
  } else {
    wifiConnected = false;
    Serial.println("WiFi connection failed!");
    digitalWrite(LED_RED, HIGH); // Nyala merah terus kalau gagal
  }
}

// *** Fungsi Sensor (Tidak Berubah, Sudah Bagus) ***
float readUltrasonicCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 60000); // 60 ms
  
  if (duration == 0) {
    return -1.0;
  }
  
  float distance_cm = (duration / 2.0) * 0.0343;
  return distance_cm;
}

float readFilteredUltrasonic() {
  float samples[NUM_ULTRASONIC_SAMPLES];
  int validSamples = 0;
  
  // Ambil beberapa sampel
  for(int i = 0; i < NUM_ULTRASONIC_SAMPLES; i++) {
    float dist = readUltrasonicCM();
    
    // Cek apakah jarak masuk akal
    if(dist >= MIN_DISTANCE_CM && dist <= MAX_DISTANCE_CM) {
      samples[validSamples++] = dist;
    }
    delay(50);
  }
  
  if(validSamples == 0) {
    Serial.println("Ultrasonic: No valid samples");
    return -1.0;
  }
  
  // Sorting manual (Bubble Sort)
  for (int i = 0; i < validSamples - 1; i++) {
    for (int j = 0; j < validSamples - i - 1; j++) {
      if (samples[j] > samples[j + 1]) {
        float temp = samples[j];
        samples[j] = samples[j + 1];
        samples[j + 1] = temp;
      }
    }
  }
  
  // Ambil nilai tengah (Median)
  float median = samples[validSamples / 2];
  return median;
}

int calculateWaterLevel(float ultrasonic_cm) {
  if (ultrasonic_cm < 0) return -1; // Error sensor

  // Hitung tinggi air (Tinggi Sensor - Jarak Terbaca)
  // Karena SENSOR_MOUNT_HEIGHT_CM = 100.0, ini adalah batas atas air 1 meter
  float water_height = SENSOR_MOUNT_HEIGHT_CM - ultrasonic_cm;
  
  // Cegah nilai tidak logis
  if (water_height < 0) water_height = 0;
  if (water_height > SENSOR_MOUNT_HEIGHT_CM) water_height = SENSOR_MOUNT_HEIGHT_CM;
  
  // Hitung persen
  float percent = (water_height / SENSOR_MOUNT_HEIGHT_CM) * 100.0;
  
  Serial.print("Jarak: "); Serial.print(ultrasonic_cm);
  Serial.print("cm | Tinggi Air: "); Serial.print(water_height);
  Serial.print("cm | Persen: "); Serial.println(percent);
  
  // Lihat diagram perhitungan level air di bawah untuk pemahaman.
  
  
  return (int)percent;
}

// *** Fungsi Output (Disederhanakan untuk Buzzer) ***
void setOutputs(int percent) {
  // Reset semua output dulu (kecuali Buzzer jika sedang berbunyi non-blocking)
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_YELLOW, LOW);
  digitalWrite(LED_RED, LOW);
  noTone(BUZZER); // Matikan tone sebelumnya

  if (percent == -1) {
    // Error Mode (Kedip Merah Kuning Hijau)
    digitalWrite(LED_RED, HIGH);
    digitalWrite(LED_YELLOW, HIGH);
    digitalWrite(LED_GREEN, HIGH);
    delay(100);
    digitalWrite(LED_RED, LOW);
    digitalWrite(LED_YELLOW, LOW);
    digitalWrite(LED_GREEN, LOW);
    return;
  }

  if (percent >= DANGER_THRESHOLD_PERCENT) {
    // BAHAYA / AWAS (>= 85% atau >= 85 cm)
    digitalWrite(LED_RED, HIGH);
    // Buzzer mode bahaya: Nyala/Mati cepat
    if ((millis() / 200) % 2 == 0) { // 200ms ON / 200ms OFF
        tone(BUZZER, 2500);
    } else {
        noTone(BUZZER);
    }
  } else if (percent >= WARNING_THRESHOLD_PERCENT) {
    // SIAGA (60% <= x < 85% atau 60 cm <= x < 85 cm)
    digitalWrite(LED_YELLOW, HIGH);
    // Buzzer mode warning: Nyala/Mati lambat
    if ((millis() / 500) % 2 == 0) { // 500ms ON / 500ms OFF
        tone(BUZZER, 1000);
    } else {
        noTone(BUZZER);
    }
  } else {
    // AMAN (< 60% atau < 60 cm)
    digitalWrite(LED_GREEN, HIGH);
  }
}

/**
 * @brief Kirim Data ke Server (API).
 * @note Tidak akan mencoba koneksi ulang. Itu tugas loop().
 */
void sendData(float ultrasonic_cm, int finalPercent) {
  if(finalPercent < 0) return; // Jangan kirim kalau sensor error
  
  // **PERBAIKAN**: Cek koneksi WiFi. Jika putus, RETURN!
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi putus, tidak bisa kirim data sekarang.");
    return; 
  }

  HTTPClient http;
  http.begin(SERVER_URL);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000); // Timeout 5 detik

  String sensorStatus = (ultrasonic_cm > 0) ? "ultrasonic_only" : "failed";

  // Buat JSON String manual
  String payload = "{";
  payload += "\"device_id\":\"esp32_01\",";
  payload += "\"ultrasonic_cm\":" + String(ultrasonic_cm) + ",";
  payload += "\"final_level_percent\":" + String(finalPercent) + ",";
  payload += "\"sensor_status\":\"" + sensorStatus + "\"";
  payload += "}";

  Serial.println("Mengirim data: " + payload);
  
  int httpResponseCode = http.POST(payload);
  
  if (httpResponseCode > 0) {
    Serial.print("✅ Sukses kirim! Response code: ");
    Serial.println(httpResponseCode);
  } else {
    Serial.print("❌ Gagal kirim. Error code: ");
    Serial.print(httpResponseCode);
    Serial.print(". Error: ");
    Serial.println(http.errorToString(httpResponseCode));
  }
  
  http.end();
}

/**
 * @brief Fungsi utama loop()
 * @note Menggunakan non-blocking delay untuk loop yang lebih responsif.
 */
void loop() {
  
  // *** PERBAIKAN UTAMA: Penanganan Koneksi WiFi yang Robust ***
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi terputus. Mencoba sambungkan ulang...");
    connectWiFi();
  }
  
  // Penanganan Buzzer di setOutputs sekarang non-blocking, jadi panggil terus.
  
  // Hanya proses baca sensor dan kirim data pada interval waktu yang ditentukan
  if (millis() - lastSampleTime >= SAMPLE_INTERVAL_MS) {
    lastSampleTime = millis();
    
    // 1. Baca Sensor
    float ultrasonic_cm = readFilteredUltrasonic();
    
    // 2. Hitung Level Air
    int finalPercent = calculateWaterLevel(ultrasonic_cm);
    
    // 3. Output LED/Buzzer (Non-Blocking)
    // NOTE: setOutputs dipanggil di luar blok if ini agar Buzzer tetap berbunyi
    // pada mode WARNING/DANGER secara non-blocking.
    
    // 4. Kirim ke Server
    sendData(ultrasonic_cm, finalPercent);
  }
  
  // 3. Output LED/Buzzer (Harus selalu dipanggil untuk Buzzer non-blocking)
  // Untuk memastikan LED/Buzzer diupdate terus-menerus
  setOutputs(calculateWaterLevel(readFilteredUltrasonic())); // Ini akan membaca sensor lagi, tapi hanya dipakai untuk update Output cepat.
  
  // Kecilkan delay minimal agar loop tetap berjalan cepat (untuk Buzzer non-blocking)
  delay(50); 
}