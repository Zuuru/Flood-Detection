# 🌊 Flood Detection Warning System

> Sistem deteksi dan peringatan dini banjir berbasis IoT menggunakan ESP32, LoRa, dan sensor ultrasonik dengan dashboard mobile Flutter.

---

## 📋 Deskripsi Proyek

Sistem ini dirancang untuk mendeteksi ketinggian air secara real-time menggunakan sensor ultrasonik HC-SR04 yang dipasang di atas permukaan air. Data jarak yang diukur kemudian dikonversi menjadi status bahaya banjir, ditampilkan melalui indikator LED & buzzer di lokasi, serta dikirimkan ke Firebase dan divisualisasikan pada aplikasi mobile Flutter.

---

## ⚙️ Cara Kerja

```
[HC-SR04] --> mengukur jarak ke permukaan air
     |
     v
  [ESP32] --> memproses data & menentukan status
     |              |
     |              v
     |         [LED + Buzzer] --> indikator lokal
     |
     v
  [LoRa] --> (opsional: transmisi jarak jauh)
     |
     v
[Firebase Realtime DB] --> menyimpan data
     |
     v
[Flutter App] --> dashboard monitoring mobile
```

### Status Level Banjir

| Status | Warna LED | Buzzer | Kondisi |
|--------|-----------|--------|---------|
| 🟢 **Aman** | Hijau | Off | Jarak air > threshold aman |
| 🟡 **Siaga** | Kuning | Beep lambat | Jarak air mendekati batas siaga |
| 🔴 **Evakuasi** | Merah | Beep cepat/terus | Jarak air mencapai batas kritis |

---

## 🛠️ Komponen Hardware

| No | Komponen | Jumlah |
|----|----------|--------|
| 1 | ESP32 | 1 |
| 2 | Modul LoRa | 1 |
| 3 | Sensor Ultrasonik HC-SR04 | 1 |
| 4 | LED (Merah, Kuning, Hijau) | 3 |
| 5 | Buzzer | 1 |
| 6 | Panel Surya | 1 |
| 7 | Baterai | 1 |
| 8 | Kabel Jumper | Secukupnya |

---

## 💻 Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Firmware | Arduino IDE (C++) |
| Mikrokontroler | ESP32 |
| Database | Firebase Realtime Database |
| Mobile App | Flutter (Dart) |
| Komunikasi | WiFi (ESP32 → Firebase), LoRa (opsional) |

---

## 📁 Struktur Repositori

```
flood-detection-warning/
├── firmware/
│   ├── flood_detection.ino       # Kode utama ESP32
│   └── config.h                  # Konfigurasi threshold & pin
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   └── dashboard_screen.dart
│   │   ├── models/
│   │   │   └── flood_data.dart
│   │   └── services/
│   │       └── firebase_service.dart
│   └── pubspec.yaml
├── docs/
│   ├── README.md
│   ├── HARDWARE.md
│   ├── ARDUINO_CODE.md
│   ├── FIREBASE.md
│   └── FLUTTER_APP.md
└── assets/
    └── wiring_diagram.png
```

---

## 🚀 Cara Menjalankan

### 1. Setup Hardware
Lihat [HARDWARE.md](./HARDWARE.md) untuk diagram wiring lengkap.

### 2. Upload Firmware
1. Buka `firmware/flood_detection.ino` di Arduino IDE
2. Install library yang dibutuhkan (lihat [ARDUINO_CODE.md](./ARDUINO_CODE.md))
3. Sesuaikan konfigurasi WiFi & Firebase di `config.h`
4. Upload ke ESP32

### 3. Setup Firebase
Ikuti langkah di [FIREBASE.md](./FIREBASE.md) untuk membuat project dan mengatur Realtime Database.

### 4. Jalankan Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```
Lihat [FLUTTER_APP.md](./FLUTTER_APP.md) untuk konfigurasi lengkap.

---

## 👥 Tim Pengembang

> Isi dengan nama anggota tim

---

## 📄 Lisensi

Project ini dibuat untuk keperluan Tugas Besar mata kuliah Internet of Things.
