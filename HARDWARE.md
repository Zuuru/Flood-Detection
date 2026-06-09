# 🔧 Dokumentasi Hardware — Flood Detection Warning System

## Daftar Komponen

| No | Komponen | Spesifikasi | Fungsi |
|----|----------|-------------|--------|
| 1 | ESP32 | 38-pin / 30-pin | Mikrokontroler utama, WiFi, kontrol semua perangkat |
| 2 | Modul LoRa | *Dihapus dari proyek* | Tidak digunakan (LoRa dinonaktifkan) |
| 3 | Sensor Ultrasonik | HC-SR04 | Mengukur jarak permukaan air ke sensor |
| 4 | LED Hijau | 5mm | Indikator status Aman |
| 5 | LED Kuning | 5mm | Indikator status Siaga |
| 6 | LED Merah | 5mm | Indikator status Evakuasi |
| 7 | Buzzer | Aktif 5V | Alarm peringatan suara |
| 8 | Panel Surya | 5V/6V (sesuaikan) | Sumber energi utama |
| 9 | Baterai | Li-Ion / LiPo 3.7V atau 18650 | Penyimpan energi cadangan |
| 10 | Kabel Jumper | Male-Male / Male-Female | Koneksi antar komponen |

---

## Konfigurasi Pin ESP32

### Sensor Ultrasonik HC-SR04

| Pin HC-SR04 | Pin ESP32 | Keterangan |
|-------------|-----------|------------|
| VCC | 5V / Vin | Tegangan 5V |
| GND | GND | Ground |
| TRIG | GPIO 5 | Trigger sinyal ultrasonik |
| ECHO | GPIO 18 | Menerima pantulan sinyal |

> ⚠️ **Catatan:** ESP32 bekerja pada logika 3.3V. Pin ECHO HC-SR04 mengeluarkan 5V — gunakan **voltage divider** (resistor 1kΩ + 2kΩ) pada jalur ECHO untuk melindungi ESP32.

### Voltage Divider untuk ECHO Pin

```
ECHO (5V) ---[1kΩ]---+---[2kΩ]--- GND
                      |
                   GPIO 18 (ESP32)
```

### LED

| LED | Pin ESP32 | Resistor |
|-----|-----------|----------|
| LED Hijau (Aman) | GPIO 25 | 220Ω |
| LED Kuning (Siaga) | GPIO 26 | 220Ω |
| LED Merah (Evakuasi) | GPIO 27 | 220Ω |

Wiring LED (masing-masing):
```
GPIO --> [220Ω] --> LED (Anoda) --> LED (Katoda) --> GND
```

### Buzzer

| Pin Buzzer | Pin ESP32 |
|------------|-----------|
| + (positif) | GPIO 14 |
| - (negatif) | GND |

## Diagram Wiring (Deskriptif)

```
                                                            +------------------+
                                                            |      ESP32       |
     HC-SR04               |                  |
     --------              |  GPIO5  --> TRIG |
     VCC  --> 5V           |  GPIO18 <-- ECHO |
     GND  --> GND          |                  |
     TRIG <-- GPIO5        |  GPIO25 --> LED Hijau --> 220Ω --> GND
     ECHO --> GPIO18*      |  GPIO26 --> LED Kuning -> 220Ω --> GND
                                                            |  GPIO27 --> LED Merah --> 220Ω --> GND
                                                            |  GPIO14 --> Buzzer (+) --> GND
                                                            |                  |
                                                            |                  |
                                                            |                  |
                                                            +------------------+
                                                                           |   |
                                                                      3.3V  GND
                                                                           |
                                                            Panel Surya
                                                            + Baterai
                                                            (melalui modul TP4056 / charging module)
```

---

## Sistem Catu Daya

```
[Panel Surya] --> [Modul TP4056 / Solar Charge Controller]
                             |
                        [Baterai Li-Ion]
                             |
                      [Step-up / Boost 5V] --> [ESP32 via Vin/5V]
```

**Rekomendasi komponen tambahan:**
- Modul TP4056 untuk charging baterai dari panel surya
- Modul boost converter MT3608 jika tegangan baterai perlu dinaikkan ke 5V
- ESP32 dapat langsung menerima 3.7V pada pin 3V3 (cek datasheet board yang digunakan)

---

## Penempatan Alat

```
Struktur/Tiang
     |
     |--[Sensor HC-SR04] <-- dipasang menghadap ke bawah (ke permukaan air)
     |
     |--[ESP32 + LoRa]   <-- di dalam kotak weatherproof (IP65)
     |
     |--[LED + Buzzer]   <-- menghadap ke luar agar terlihat/terdengar
     |
     |--[Panel Surya]    <-- menghadap atas, tidak terhalangi
     |
[===Permukaan Air===]    <-- referensi titik 0
```

**Titik Pemasangan Sensor:**
- Sensor dipasang pada ketinggian tetap (contoh: 200 cm dari dasar sungai)
- Jarak yang diukur adalah dari sensor ke permukaan air
- Semakin kecil jarak = semakin tinggi air = semakin bahaya

---

## Threshold Ketinggian Air

> Sesuaikan nilai berikut dengan kondisi lapangan saat konfigurasi

| Status | Kondisi Jarak Sensor ke Air | Arti |
|--------|-----------------------------|------|
| 🟢 Aman | Jarak > 150 cm | Air masih jauh dari sensor |
| 🟡 Siaga | 80 cm < Jarak ≤ 150 cm | Air mulai naik |
| 🔴 Evakuasi | Jarak ≤ 80 cm | Air mendekati sensor / sangat tinggi |

---

## Checklist Perakitan

- [ ] Semua koneksi pin sudah sesuai tabel
- [ ] Voltage divider pada pin ECHO HC-SR04 terpasang
- [ ] Resistor 220Ω pada setiap LED terpasang
- [ ] Modul LoRa mendapat supply 3.3V (bukan 5V)
- [ ] Sistem catu daya baterai + panel surya terhubung
- [ ] Alat dikemas dalam wadah tahan air (weatherproof)
- [ ] Sensor HC-SR04 menghadap ke permukaan air tanpa halangan
