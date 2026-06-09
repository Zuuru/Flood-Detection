# 🔥 Dokumentasi Firebase — Flood Detection Warning System

## Setup Firebase Project

### Langkah 1: Buat Project Firebase

1. Buka [https://console.firebase.google.com](https://console.firebase.google.com)
2. Klik **"Add Project"**
3. Masukkan nama project, contoh: `flood-detection-iot`
4. Nonaktifkan Google Analytics (opsional)
5. Klik **"Create Project"**

### Langkah 2: Aktifkan Realtime Database

1. Di sidebar kiri, pilih **Build → Realtime Database**
2. Klik **"Create Database"**
3. Pilih lokasi server (pilih `asia-southeast1` untuk server terdekat)
4. Pilih mode **"Start in test mode"** (untuk development)
5. Klik **"Enable"**

### Langkah 3: Ambil Kredensial

Untuk **ESP32 (Arduino)**:
1. Buka **Project Settings → Service Accounts**
2. Di bagian **Database Secrets**, klik **"Show"** untuk mendapatkan legacy secret
3. Salin URL database: `https://nama-project-default-rtdb.asia-southeast1.firebasedatabase.app/`

Untuk **Flutter**:
1. Di **Project Settings**, tab **General**
2. Di bagian **"Your apps"**, klik ikon Android (➕ Add app)
3. Daftarkan package name Flutter (contoh: `com.example.flood_detection`)
4. Download file `google-services.json`
5. Letakkan di folder `android/app/`

---

## Struktur Realtime Database

```json
{
  "sensor": {
    "jarak_cm": 123.5,
    "status": "SIAGA",
    "timestamp": 1700000000000
  },
  "history": {
    "1700000000000": {
      "jarak_cm": 123.5,
      "status": "SIAGA",
      "timestamp": 1700000000000
    },
    "1700000005000": {
      "jarak_cm": 115.2,
      "status": "SIAGA",
      "timestamp": 1700000005000
    },
    "1700000010000": {
      "jarak_cm": 72.1,
      "status": "EVAKUASI",
      "timestamp": 1700000010000
    }
  }
}
```

### Penjelasan Node

| Path | Tipe Data | Deskripsi |
|------|-----------|-----------|
| `/sensor/jarak_cm` | Float | Jarak terkini sensor ke permukaan air (cm) |
| `/sensor/status` | String | Status terkini: `AMAN`, `SIAGA`, atau `EVAKUASI` |
| `/sensor/timestamp` | Integer | Waktu pengukuran terakhir (Unix timestamp / millis) |
| `/history/{timestamp}` | Object | Riwayat data per interval pengiriman |
| `/history/{timestamp}/jarak_cm` | Float | Jarak saat pencatatan riwayat |
| `/history/{timestamp}/status` | String | Status saat pencatatan riwayat |
| `/history/{timestamp}/timestamp` | Integer | Waktu pencatatan |

---

## Security Rules

### Mode Development (Test Mode)

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

> ⚠️ Hanya gunakan ini saat pengembangan. Jangan di-deploy ke produksi!

### Mode Produksi (Recommended)

```json
{
  "rules": {
    "sensor": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "history": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

Untuk ESP32 yang tidak menggunakan autentikasi user, gunakan **legacy database secret** sebagai token admin.

---

## Cara Mengakses Data dari Firebase (REST API)

Bisa diuji langsung via browser atau Postman:

```
GET https://nama-project-default-rtdb.asia-southeast1.firebasedatabase.app/sensor.json
```

Contoh response:
```json
{
  "jarak_cm": 123.5,
  "status": "SIAGA",
  "timestamp": 1700000000000
}
```

---

## Mengelola Data History

Karena data history akan terus bertambah, sebaiknya terapkan strategi pembersihan data berkala:

### Opsi 1: Firebase Cloud Functions (Auto-delete)

Buat Cloud Function untuk menghapus data history yang lebih dari 7 hari:

```javascript
// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.cleanOldHistory = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const db = admin.database();
    const ref = db.ref("history");
    const cutoff = Date.now() - 7 * 24 * 60 * 60 * 1000; // 7 hari lalu

    const snapshot = await ref.orderByKey().endAt(cutoff.toString()).get();
    if (snapshot.exists()) {
      await snapshot.ref.remove();
      console.log("History lama berhasil dihapus.");
    }
  });
```

### Opsi 2: Batasi di Flutter

Saat mengambil riwayat, batasi hanya mengambil 50 data terakhir:

```dart
// Ambil 50 data history terbaru
final snapshot = await FirebaseDatabase.instance
    .ref('history')
    .orderByKey()
    .limitToLast(50)
    .get();
```

---

## Checklist Setup Firebase

- [ ] Project Firebase sudah dibuat
- [ ] Realtime Database sudah diaktifkan
- [ ] URL database sudah disalin ke `config.h` (ESP32)
- [ ] Legacy secret / API key sudah disalin ke `config.h` (ESP32)
- [ ] File `google-services.json` sudah diunduh dan diletakkan di `android/app/`
- [ ] Security rules sudah dikonfigurasi
- [ ] Koneksi ESP32 ke Firebase berhasil diuji
