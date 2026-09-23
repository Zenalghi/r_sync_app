# R-Sync (Relay-Sync) Client App 🌐📱💻

Aplikasi kontrol dan pemantau perangkat cerdas multiplatform (*Cross-Platform Client*) untuk perangkat mikrokontroler **ESP32 Local Server**. Aplikasi ini mendukung sistem operasi **Android, iOS, Web, Windows, macOS, dan Linux** secara *native* tanpa ketergantungan pada server cloud pihak ketiga (*100% Local LAN Communication*).

- **Repositori Aplikasi Flutter**: [https://github.com/Zenalghi/r_sync_app](https://github.com/Zenalghi/r_sync_app)
- **Firmware ESP32 Terkait**: [https://github.com/Zenalghi/relay-local-server](https://github.com/Zenalghi/relay-local-server)
- **Framework**: Flutter 3 (Dart SDK ^3.13)
- **Arsitektur State Management**: Provider (MVVM / Controller Pattern)

---

## 📋 Daftar Isi
1. [Fitur Utama](#-fitur-utama)
2. [Desain Sistem & Estetika](#-desain-sistem--estetika)
3. [Arsitektur Navigasi Adaptif](#-arsitektur-navigasi-adaptif)
4. [Struktur Folder Proyek](#-struktur-folder-proyek)
5. [Kontrak Komunikasi REST API ESP32](#-kontrak-komunikasi-rest-api-esp32)
6. [Panduan Menjalankan & Build Aplikasi](#-panduan-menjalankan--build-aplikasi)

---

## ⚡ Fitur Utama

- **Smart Dynamic Discovery & Local Caching**:
  - Aplikasi secara otomatis mendeteksi jumlah hardware (relay & saklar servo) dan fitur (timer & scheduler) saat terhubung ke ESP32 via `GET /api/capabilities`.
  - Kapabilitas tersimpan otomatis di `SharedPreferences` sehingga saat aplikasi dibuka kembali, layout yang sudah pernah terkoneksi tidak kembali kosong.
- **Multi-Relay Control**: Kontrol saklar manual instan untuk 4 Channel Relay dengan *optimistic UI update* dan *fallback* otomatis jika koneksi jaringan terputus.
- **Wall Switch Servo Control (3 Saklar Tembok)**:
  - Mengontrol 3 saklar tembok fisik menggunakan 6 servo (Switch A, B, C).
  - Dilengkapi tombol *Tes 3x Servo* untuk menguji pergerakan mekanis servo secara langsung.
- **Kalibrasi Sudut Servo (Rest & Press Angle)**:
  - Pengaturan slider interaktif untuk `Rest Angle` (0°–180°), `Press Angle` (0°–180°), dan durasi tekanan di layar Pengaturan.
- **10-Slot Countdown Timer**:
  - Layar pewaktu hitung mundur (HH:MM:SS) dengan pemilihan target bebas (Relay 1..4 & Saklar A..C), aksi target (ON/OFF), serta checkbox *"Lakukan kebalikan saat mulai & selesai"*.
  - Dilengkapi indikator progress bar dan kontrol *Jeda*, *Lanjutkan*, atau *Batalkan*.
- **7-Channel Smart Scheduler**:
  - Penjadwalan otomatis berbasis jam harian (masing-masing 4 slot per channel relay/saklar) dengan rekomendasi cerdas *auto-alternating* (ON ➡️ OFF ➡️ ON).
- **Remote OLED Display Control**:
  - Mengganti 4 halaman tampilan layar fisik SSD1306 di ESP32 langsung dari smartphone atau PC.
- **Remote Wi-Fi Reset**:
  - Memicu pembukaan Captive Portal AP ESP32 secara jarak jauh dari halaman Pengaturan saat ingin memindahkan perangkat ke jaringan baru.

---

## 🎨 Desain Sistem & Estetika

Aplikasi ini dibangun menggunakan palet warna khusus dengan tipografi **Poppins**:

| Token Warna | Hex Code | Peran Visual |
| :--- | :--- | :--- |
| **Teal** | `#178697` | Aksen primer, status Relay & Saklar aktif |
| **Orange** | `#EC651C` | Aksen sekunder, status peringatan & kontrol OLED |
| **Dark Slate / Surface**| `#181E25` / `#222A35` | Latar belakang & kartu container Dark Mode |
| **Light Card / Background** | `#F8F9FA` / `#FFFFFF` | Latar belakang & kartu container Light Mode |
| **Emerald** | `#10B981` | Indikator koneksi sukses & status job aktif |
| **Error / Crimson** | `#EF4444` | Indikator koneksi terputus & tombol hapus |

---

## 📱🖥️ Arsitektur Navigasi Adaptif (*Adaptive Navigation*)

- **Mobile (Android & iOS)**: **Bottom Navigation Bar** 4 tab (Dashboard, Timer, Scheduler, Pengaturan).
- **Desktop (Windows, macOS, Linux) & Web**: **Left Sidebar Navigation Rail** responsif di sisi kiri dengan tombol *Expand / Collapse*.

---

## 📂 Struktur Folder Proyek

```text
r_sync_app/
├── assets/
│   ├── fonts/                   # Font Poppins (Regular, Medium, SemiBold, Bold)
│   └── icons/ico.png            # Icon resmi aplikasi R-Sync
│
├── lib/
│   ├── constants/
│   │   ├── app_colors.dart      # Definisi token warna desain R-Sync
│   │   └── app_theme.dart       # Konfigurasi ThemeData (Light Mode & Dark Mode)
│   │
│   ├── models/
│   │   ├── esp_capabilities.dart# Model kapabilitas hardware & lokal persistence
│   │   ├── esp_status.dart      # Model parsing JSON respon /api/status ESP32
│   │   ├── timer_job.dart       # Model countdown timer aktif
│   │   └── schedule_job.dart    # Model jadwal slot (jam, menit, aksi, aktif)
│   │
│   ├── providers/
│   │   ├── esp_provider.dart    # State management koneksi ESP32 & kontrol hardware
│   │   ├── schedule_provider.dart # State management scheduler & sinkronisasi jadwal
│   │   └── theme_provider.dart  # State management tema Light/Dark mode
│   │
│   ├── screens/
│   │   ├── main_screen.dart     # Shell navigasi adaptif (4 Tab Navigation)
│   │   ├── dashboard_screen.dart# Kontrol relay & saklar tembok servo
│   │   ├── timer_screen.dart    # Layar daftar timer countdown & modal pembuat
│   │   ├── scheduler_screen.dart# Daftar jadwal otomatis per channel
│   │   └── settings_screen.dart # Konfigurasi IP, kalibrasi servo, tema, & polaritas
│   │
│   ├── services/
│   │   ├── api_service.dart     # Client HTTP REST API komunikasi ke ESP32
│   │   └── storage_service.dart # Wrapper SharedPreferences untuk simpan IP & tema
│   │
│   ├── widgets/
│   │   ├── relay_card.dart      # Kartu saklar relay
│   │   ├── wall_switch_card.dart# Kartu saklar tembok 2-servo
│   │   ├── schedule_card.dart   # Kartu item jadwal
│   │   └── status_badge.dart    # Badge header status IP & konektivitas
│   │
│   └── main.dart                # Entry point aplikasi Flutter & MultiProvider setup
│
└── pubspec.yaml                 # Manifest dependensi & konfigurasi versi aplikasi
```

---

## 🚀 Panduan Menjalankan & Build Aplikasi

### Menjalankan Mode Development:
```powershell
# Jalankan di Android Emulator
flutter run -d emulator

# Jalankan di Browser Web (Chrome)
flutter run -d chrome

# Jalankan di Desktop Windows
flutter run -d windows
```

### Menjalankan Automated Testing:
```powershell
flutter test
```

### Memeriksa Kualitas Kode (*Static Analysis*):
```powershell
flutter analyze
```

---
*Proyek ini merupakan bagian dari ekosistem open-source **R-Sync** oleh **Zenalghi** ([Aplikasi Flutter Client](https://github.com/Zenalghi/r_sync_app) • [Firmware ESP32 Local Server](https://github.com/Zenalghi/relay-local-server)).*
