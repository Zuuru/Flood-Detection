# 🔥 Firebase Database Setup — Flood Detection

## Overview

Database structure untuk menyimpan data sensor real-time dan history pengukuran. Firmware ESP32 akan mengirim data ke path `/sensor/` setiap 5 detik dan menyimpan history di `/history/`.

---

## 1. Database Structure (JSON)

Paste struktur berikut ke Firebase Console sebagai initial data:

```json
{
  "sensor": {
    "jarak_cm": 150.5,
    "status": "AMAN",
    "timestamp": 1623456789000
  },
  "history": {
    "1623456789000": {
      "jarak_cm": 150.5,
      "status": "AMAN",
      "timestamp": 1623456789000
    },
    "1623456794000": {
      "jarak_cm": 148.2,
      "status": "AMAN",
      "timestamp": 1623456794000
    }
  },
  "config": {
    "alert_threshold": 85,
    "alert_cooldown_minutes": 10
  }
}
```

### Path Explanation

| Path | Tipe | Fungsi |
|------|------|--------|
| `/sensor/jarak_cm` | float | Jarak terakhir terukur (cm) |
| `/sensor/status` | string | Status: `AMAN`, `SIAGA`, `EVAKUASI` |
| `/sensor/timestamp` | integer | Unix timestamp pengukuran terakhir (ms) |
| `/history/{timestamp}` | JSON | Penyimpanan history dengan key = timestamp |
| `/config/alert_threshold` | integer | Threshold alert (persentase) |
| `/config/alert_cooldown_minutes` | integer | Cooldown antar alert (menit) |

---

## 2. Security Rules

Replace aturan default Firebase dengan rules berikut agar ESP32 dapat menulis data:

```json
{
  "rules": {
    "sensor": {
      ".read": true,
      ".write": true,
      "jarak_cm": {
        ".validate": "newData.isNumber()"
      },
      "status": {
        ".validate": "newData.isString()"
      },
      "timestamp": {
        ".validate": "newData.isNumber()"
      }
    },
    "history": {
      ".read": true,
      ".write": true,
      "$timestamp": {
        ".validate": "newData.hasChildren(['jarak_cm', 'status', 'timestamp'])"
      }
    },
    "config": {
      ".read": true,
      ".write": false
    }
  }
}
```

> ⚠️ **PENTING:** Rules di atas mengizinkan siapa saja membaca dan menulis ke `/sensor/` & `/history/`. 
> **Untuk production, gunakan rules yang lebih ketat** dan implementasikan authentication (e.g., custom tokens).

---

## 3. Setup Steps

### Step 1: Buka Firebase Console

1. Pergi ke https://console.firebase.google.com/
2. Pilih project `Flood Detection`
3. Di menu kiri, klik `Build` → `Realtime Database`

### Step 2: Input Initial Data

1. Klik tombol **"+"** untuk menambah data, atau
2. Pilih **"..."** (menu) → **"Import JSON"** 
3. Paste struktur JSON dari bagian **1. Database Structure** di atas

Alternatively, jika ingin manual:
- Buat node `sensor`, `history`, dan `config` secara manual
- Atau biarkan kosong — data akan dibuat otomatis saat ESP32 pertama kali mengirim

### Step 3: Update Security Rules

1. Di halaman Realtime Database, klik tab **"Rules"**
2. Replace seluruh isi dengan rules dari bagian **2. Security Rules** di atas
3. Klik **"Publish"**

### Step 4: Verifikasi Database Secret (untuk Arduino code)

1. Pergi ke `Project settings` (ikon roda gigi) → `Service accounts`
2. Scroll ke bagian **"Database secrets"** (Legacy)
3. Klik **"Show"** untuk melihat secret/token
4. Copy token tersebut ke `firmware/config.h`:
   ```cpp
   #define FIREBASE_AUTH   "YOUR_DATABASE_SECRET_HERE"
   ```

---

## 4. Testing Workflow

### 4.1 Siapkan ESP32 + Sensor

1. Update `firmware/config.h`:
   ```cpp
   #define WIFI_SSID       "nama_wifi_kamu"
   #define WIFI_PASSWORD   "password_wifi_kamu"
   #define FIREBASE_HOST   "https://flood-detection-6299c-default-rtdb.asia-southeast1.firebasedatabase.app/"
   #define FIREBASE_AUTH   "YOUR_DATABASE_SECRET_HERE"
   ```

2. Upload firmware ke ESP32:
   - Buka `firmware/flood_detection.ino` di Arduino IDE
   - Tools → Board: ESP32 Dev Module
   - Tools → Upload Speed: 921600
   - Klik Upload

3. Buka Serial Monitor (Ctrl+Shift+M) untuk melihat debug output

### 4.2 Monitoring Data di Firebase Console

1. Setelah ESP32 upload & power on, buka Realtime Database di Firebase Console
2. Lihat node `/sensor/`:
   - `jarak_cm` harus berubah setiap ~5 detik
   - `status` harus berubah sesuai jarak (AMAN, SIAGA, EVAKUASI)
   - `timestamp` harus update

3. Lihat node `/history/`:
   - Entry baru harus dibuat setiap 5 detik dengan key = timestamp

### 4.3 Troubleshooting

**Problem: Data tidak muncul di Firebase**
- ✓ Cek WiFi: ESP32 harus terhubung WiFi (lihat Serial Monitor)
- ✓ Cek FIREBASE_HOST: Harus pakai https:// dan slash di akhir
- ✓ Cek FIREBASE_AUTH: Harus copy dari Database secrets (bukan API key)
- ✓ Cek security rules: Pastikan `.write: true` pada `/sensor/` dan `/history/`

**Problem: Serial Monitor menunjukkan "Firebase tidak siap"**
- ✓ Tunggu beberapa detik (Firebase perlu waktu koneksi)
- ✓ Cek koneksi internet ESP32 stabil

**Problem: Banyak data di `/history/`, terlalu besar**
- ✓ Normal untuk testing. Bisa di-clean dengan delete `/history/` node
- ✓ Untuk production, implementasikan data archival/cleanup

---

## 5. Database Maintenance

### Backup Data

Firebase Console → Realtime Database → **"..."** → **"Export JSON"**

### Clean/Reset Data

1. Klik pada node yang ingin dihapus
2. Pilih **"..."** → **"Delete"**
3. Konfirmasi

---

## 6. Flutter App Integration

Setelah database setup selesai, update Flutter app dengan:

```bash
cd mobile_app
flutterfire configure --project=flood-detection-6299c
```

Ini akan auto-generate `lib/firebase_options.dart` dengan credential yang benar.

Kemudian update `lib/services/firebase_service.dart` untuk membaca data dari `/sensor/` dan `/history/`.

---

## Quick Summary

| Langkah | Action |
|---------|--------|
| 1 | Import initial JSON structure ke Firebase |
| 2 | Update security rules untuk read/write access |
| 3 | Copy database secret ke `firmware/config.h` |
| 4 | Upload firmware ke ESP32 |
| 5 | Monitor data di Firebase Console |
| 6 | Troubleshoot jika ada error |
| 7 | (Opsional) Setup Flutter app dengan `flutterfire configure` |
