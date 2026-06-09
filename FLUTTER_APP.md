# 📱 Dokumentasi Flutter App — Flood Detection Warning System

## Gambaran Umum

Aplikasi Flutter berfungsi sebagai **dashboard monitoring mobile** yang menampilkan:
- Status banjir terkini secara real-time
- Jarak sensor ke permukaan air
- Riwayat data pengukuran
- Indikator visual warna sesuai level bahaya

---

## Setup Project Flutter

### 1. Buat Project Baru

```bash
flutter create flood_detection
cd flood_detection
```

### 2. Tambahkan Dependencies

Edit `pubspec.yaml`:

```yaml
name: flood_detection
description: Flood Detection Warning System Dashboard

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_database: ^10.3.9
  
  # UI
  fl_chart: ^0.66.0          # Grafik riwayat data
  intl: ^0.19.0              # Format tanggal & angka
  google_fonts: ^6.1.0       # Font kustom

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

Jalankan:
```bash
flutter pub get
```

### 3. Konfigurasi Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Konfigurasi otomatis (pastikan sudah login ke Firebase CLI)
flutterfire configure
```

Atau secara manual: letakkan `google-services.json` di `android/app/`.

---

## Struktur Folder

```
lib/
├── main.dart
├── firebase_options.dart          # Auto-generated oleh FlutterFire CLI
├── models/
│   └── flood_data.dart            # Model data sensor
├── services/
│   └── firebase_service.dart      # Service koneksi Firebase
└── screens/
    └── dashboard_screen.dart      # Halaman utama dashboard
```

---

## Kode Lengkap

### `lib/models/flood_data.dart`

```dart
class FloodData {
  final double jarakCm;
  final String status;
  final int timestamp;

  FloodData({
    required this.jarakCm,
    required this.status,
    required this.timestamp,
  });

  factory FloodData.fromMap(Map<dynamic, dynamic> map) {
    return FloodData(
      jarakCm:   (map['jarak_cm'] as num).toDouble(),
      status:    map['status']    as String,
      timestamp: map['timestamp'] as int,
    );
  }

  // Konversi status ke warna
  static statusColor(String status) {
    switch (status) {
      case 'AMAN':
        return const Color(0xFF4CAF50); // Hijau
      case 'SIAGA':
        return const Color(0xFFFFC107); // Kuning
      case 'EVAKUASI':
        return const Color(0xFFF44336); // Merah
      default:
        return const Color(0xFF9E9E9E); // Abu-abu
    }
  }

  static statusEmoji(String status) {
    switch (status) {
      case 'AMAN':      return '🟢';
      case 'SIAGA':     return '🟡';
      case 'EVAKUASI':  return '🔴';
      default:          return '⚪';
    }
  }
}
```

### `lib/services/firebase_service.dart`

```dart
import 'package:firebase_database/firebase_database.dart';
import '../models/flood_data.dart';

class FirebaseService {
  final DatabaseReference _sensorRef =
      FirebaseDatabase.instance.ref('sensor');
  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref('history');

  // Stream data sensor terkini (real-time)
  Stream<FloodData?> getSensorStream() {
    return _sensorRef.onValue.map((event) {
      if (event.snapshot.value == null) return null;
      final data = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map);
      return FloodData.fromMap(data);
    });
  }

  // Ambil 20 riwayat data terbaru
  Future<List<FloodData>> getHistory() async {
    final snapshot = await _historyRef
        .orderByKey()
        .limitToLast(20)
        .get();

    if (!snapshot.exists) return [];

    final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final list = map.values
        .map((v) => FloodData.fromMap(Map<dynamic, dynamic>.from(v)))
        .toList();

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}
```

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FloodDetectionApp());
}

class FloodDetectionApp extends StatelessWidget {
  const FloodDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
```

### `lib/screens/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/flood_data.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _service = FirebaseService();
  List<FloodData> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _service.getHistory();
    setState(() => _history = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌊 Flood Detection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          )
        ],
      ),
      body: StreamBuilder<FloodData?>(
        stream: _service.getSensorStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === Card Status Terkini ===
                _buildStatusCard(data),
                const SizedBox(height: 16),

                // === Card Jarak Sensor ===
                _buildJarakCard(data),
                const SizedBox(height: 16),

                // === Riwayat Data ===
                _buildHistoryCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(FloodData? data) {
    final status = data?.status ?? 'Memuat...';
    final color = data != null
        ? FloodData.statusColor(status)
        : Colors.grey;
    final emoji = data != null ? FloodData.statusEmoji(status) : '⚪';

    return Card(
      elevation: 4,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              'Status Banjir',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJarakCard(FloodData? data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoTile(
              icon: Icons.straighten,
              label: 'Jarak ke Air',
              value: data != null
                  ? '${data.jarakCm.toStringAsFixed(1)} cm'
                  : '-',
            ),
            _buildInfoTile(
              icon: Icons.access_time,
              label: 'Terakhir Update',
              value: data != null
                  ? DateFormat('HH:mm:ss').format(
                      DateTime.fromMillisecondsSinceEpoch(data.timestamp))
                  : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon,
      required String label,
      required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Riwayat Data',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada riwayat data'),
              ))
            else
              ..._history.reversed.map((item) {
                final color = FloodData.statusColor(item.status);
                final time = DateFormat('dd/MM HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(item.timestamp));
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(FloodData.statusEmoji(item.status)),
                  ),
                  title: Text(item.status,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.jarakCm.toStringAsFixed(1)} cm'),
                  trailing: Text(time,
                      style: const TextStyle(fontSize: 12)),
                );
              }),
          ],
        ),
      ),
    );
  }
}
```

---

## Fitur Dashboard

| Fitur | Deskripsi |
|-------|-----------|
| 🔴🟡🟢 Status Card | Menampilkan status terkini dengan warna indikator |
| 📏 Jarak Sensor | Menampilkan jarak sensor ke permukaan air dalam cm |
| 🕐 Waktu Update | Waktu terakhir data diperbarui |
| 📋 Riwayat | Daftar 20 pengukuran terakhir |
| 🔄 Real-time | Data otomatis diperbarui saat ada perubahan (Stream) |
| Pull-to-refresh | Tarik layar ke bawah untuk refresh riwayat |

---

## Build & Run

```bash
# Jalankan di emulator / device
flutter run

# Build APK release
flutter build apk --release

# Build APK split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi
```

APK hasil build ada di: `build/app/outputs/flutter-apk/`

---

## Checklist Setup Flutter

- [ ] `pubspec.yaml` sudah diperbarui dan `flutter pub get` sudah dijalankan
- [ ] `google-services.json` sudah ada di `android/app/`
- [ ] `firebase_options.dart` sudah di-generate (`flutterfire configure`)
- [ ] `Firebase.initializeApp()` dipanggil di `main.dart`
- [ ] App dapat menerima data real-time dari Firebase
- [ ] Indikator status berwarna sesuai level bahaya
