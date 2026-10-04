# R-Sync (Relay-Sync) Client App 🌐📱💻

Aplikasi kontrol dan pemantau perangkat cerdas multiplatform (*Cross-Platform Client*) berbasis Flutter untuk perangkat mikrokontroler **ESP32 Local Server**. Aplikasi ini mendukung sistem operasi **Android, iOS, Web, Windows, macOS, dan Linux** secara *native* tanpa ketergantungan pada server cloud pihak ketiga (*100% Local LAN Communication*).

- **Repositori Aplikasi Flutter**: [https://github.com/Zenalghi/r_sync_app](https://github.com/Zenalghi/r_sync_app)
- **Firmware ESP32 Terkait**: [https://github.com/Zenalghi/relay-local-server](https://github.com/Zenalghi/relay-local-server)
- **Dokumentasi AI / Local LLM Tool Calling**: [R-Sync_API_TOOL_CALLING.md](file:///c:/Nova/relay-local-server/R-Sync_API_TOOL_CALLING.md)
- **Framework**: Flutter 3 (Dart SDK ^3.13)
- **Arsitektur State Management**: Provider (MVVM / Controller Pattern)
- **Versi Aplikasi**: `1.1.5+1`

---

## 📋 Daftar Isi
1. [Fitur Utama & Kapabilitas Aplikasi](#-fitur-utama--kapabilitas-aplikasi)
2. [Desain Sistem & Estetika Visual](#-desain-sistem--estetika-visual)
3. [Arsitektur Navigasi Adaptif](#-arsitektur-navigasi-adaptif)
4. [Struktur Folder & Penjelasan Lengkap Modul `lib/`](#-struktur-folder--penjelasan-lengkap-modul-lib)
5. [Alur Komunikasi & Kontrak REST API ESP32](#-alur-komunikasi--kontrak-rest-api-esp32)
6. [Mekanisme Optimistic UI & Keandalan Jaringan](#-mekanisme-optimistic-ui--keandalan-jaringan)
7. [Panduan Menjalankan, Pengujian, & Build](#-panduan-menjalankan-pengujian--build)

---

## ⚡ Fitur Utama & Kapabilitas Aplikasi

- **Smart Dynamic Discovery & Local Caching**:
  - Aplikasi secara otomatis mendeteksi kapabilitas hardware ESP32 (`GET /api/capabilities`) meliputi jumlah relay aktif, jumlah saklar dinding servo aktif, modul AC IR, ketersediaan OLED, serta kapasitas timer & scheduler.
  - Hasil discovery disimpan di `SharedPreferences` sehingga saat aplikasi dibuka tanpa koneksi jaringan, tata letak UI tidak kembali kosong (*zero layout flicker*).
- **Remote AC Pintar (IR Emitter - FLiFE / Gree YAW1F)**:
  - Antarmuka tactile modern khusus remote AC pada dashboard:
    - Pengatur suhu presisi (16°C – 30°C) dengan tombol tambah/kurang dan indikator besar.
    - Pemilihan Mode operasi: Auto, Cool, Dry, Fan, dan Heat.
    - Pemilihan Kecepatan Kipas: Auto, Min, Med, dan Max.
    - Tombol kenyamanan (Grid 2x3 Expanded): Swing Vertikal Auto, Turbo, Sleep, X-Fan (pengering kisi evaporator), I-Feel, dan Lampu LED Display.
    - Pilihan tampilan suhu layar AC: Off, Set Temp, Inside Temp, Outside Temp.
    - Sifat perintah idempoten (non-toggle) yang aman dari kesalahan status.
- **Multi-Relay Control (4 Channel)**:
  - Kontrol manual instan untuk Relay 1..4 dengan animasi gradient dinamis, *optimistic UI update*, serta pemulihan (*rollback*) otomatis jika request HTTP gagal.
- **Wall Switch Servo Control (3 Saklar Dinding)**:
  - Mengontrol saklar dinding mekanis A, B, dan C menggunakan motor servo fisik (2 servo per saklar: tombol tekan ON dan tombol tekan OFF).
  - Dilengkapi tombol *Tes 3x Servo* untuk menguji pergerakan mekanis servo secara mandiri.
- **Kalibrasi Sudut Servo & Telemetri Rail Tegangan**:
  - Pengaturan slider interaktif untuk `Rest Angle` (0°–180°), `Press Angle` (0°–180°), dan durasi penekanan tombol (`pressDurationMs`) di layar Pengaturan.
  - Penyetelan halus sudut spesifik per masing-masing servo (`pa0` sampai `pa5`).
  - Pemantauan telemetri tegangan rail servo (`servoRailMv` & `servoRailMinMv`) dan antrean FIFO servo (`servoQueueLength` & `servoBusy`).
- **10-Slot Unified Countdown Timer**:
  - Pewaktu hitung mundur mandiri (jam, menit, detik) dengan target fleksibel (Relay 1..4, Saklar A..C, dan AC ON/OFF).
  - Mode *"Lakukan Kebalikan saat Mulai & Selesai"* (`invertOnStartEnd`).
  - Indikator visual progres sisa waktu dengan kontrol *Jeda*, *Lanjutkan*, *Batalkan*, atau *Hapus Riwayat*.
- **10-Slot Smart NTP Scheduler**:
  - Penjadwalan harian otomatis berbasis waktu NTP (WIB UTC+7) untuk Relay 1..4, Saklar A..C, dan AC Remote.
  - Rekomendasi cerdas *auto-alternating* (otomatis menyarankan aksi target bergantian antara ON dan OFF).
- **Port Hardware Aktif Dinamis**:
  - Kemampuan mengaktifkan/menonaktifkan channel relay, saklar tembok, atau port AC secara terpisah langsung dari halaman Pengaturan (`/api/hardware/config`).
- **Remote OLED Display & Polaritas Relay**:
  - Mengganti halaman tampilan layar OLED fisik ESP32 (Halaman 0: Status, 1: Jadwal, 2: Timer, 3: Remote AC).
  - Mengubah polaritas logika relay (*Active LOW* $\leftrightarrow$ *Active HIGH*) dengan peringatan keamanan.
- **Remote Wi-Fi Reset**:
  - Mereset konfigurasi Wi-Fi ESP32 dari jarak jauh untuk memicu captive portal hotspot `R-Sync` saat memindahkan perangkat ke jaringan baru.

---

## 🎨 Desain Sistem & Estetika Visual

R-Sync mengusung identitas visual premium berbasis palet warna harmonis tetradic dengan tipografi **Poppins**:

| Token Warna | Hex Code | Peran Visual |
| :--- | :--- | :--- |
| **Teal** | `#178697` | Aksen primer, Relay 1 aktif, branding utama |
| **Teal Light / Dark** | `#38B2C6` / `#0F5A66` | Aksen hover & container gelap |
| **Orange** | `#EC651C` | Aksen sekunder, Relay 2 aktif, peringatan & status OLED |
| **Orange Light / Dark** | `#FF853F` / `#B5460B` | Aksen sekunder varian terang/gelap |
| **Indigo** | `#5C6BC0` | Aksen remote AC aktif & mode status AC |
| **Emerald (Success)** | `#10B981` | Indikator koneksi sukses & status job berjalan |
| **Crimson (Error)** | `#EF4444` | Indikator koneksi terputus & tombol hapus/batal |
| **Amber (Warning)** | `#F59E0B` | Status jeda timer & peringatan polaritas |
| **Dark Background** | `#14191F` | Latar belakang utama Dark Mode |
| **Dark Surface / Card** | `#1E2630` / `#242D37` | Container kartu & modal Dark Mode |
| **Light Background** | `#F4F7F9` | Latar belakang utama Light Mode |
| **Light Surface / Card** | `#FFFFFF` | Container kartu & modal Light Mode |

---

## 📱🖥️ Arsitektur Navigasi Adaptif (*Adaptive Navigation*)

Aplikasi menggunakan layout responsif di [main_screen.dart](file:///c:/Nova/r_sync_app/lib/screens/main_screen.dart):
- **Mobile (Android & iOS)**: **Bottom Navigation Bar** 4 tab dengan label navigasi ringkas:
  1. **Dashboard**: Kontrol relay, saklar servo, dan remote AC.
  2. **Timer**: Manajemen pewaktu hitung mundur.
  3. **Jadwal**: Manajemen jadwal otomatis harian.
  4. **Pengaturan**: Konfigurasi koneksi, kalibrasi servo, dan preferensi.
- **Desktop (Windows, macOS, Linux) & Web**: **Left Sidebar Navigation Rail** responsif di sisi kiri yang dapat diperluas (*Expanded*) atau diciutkan (*Collapsed*) untuk memaksimalkan ruang kerja layar lebar.

---

## 📂 Struktur Folder & Penjelasan Lengkap Modul `lib/`

```text
lib/
├── constants/
│   ├── app_colors.dart         # Definisi token warna desain brand R-Sync & gradients
│   └── app_theme.dart          # Konfigurasi ThemeData (Light Mode & Dark Mode) dan font Poppins
│
├── models/
│   ├── esp_capabilities.dart   # Model kapabilitas dinamis hardware & persistensi SharedPreferences
│   ├── esp_status.dart         # Model parsing payload status real-time ESP32 & telemetry AC
│   ├── schedule_job.dart       # Model entri jadwal harian multi-target (Relay, Switch, AC)
│   └── timer_job.dart          # Model countdown timer dengan durasi, sisa waktu, dan target AC
│
├── providers/
│   ├── esp_provider.dart       # State management status ESP32, polling loop, & kontrol hardware
│   ├── schedule_provider.dart  # State management jadwal harian & sinkronisasi batch
│   └── theme_provider.dart     # State management tema Light / Dark mode & persistensi
│
├── screens/
│   ├── main_screen.dart        # Shell navigasi adaptif (BottomNav di mobile, NavRail di desktop)
│   ├── dashboard_screen.dart   # Kontrol Relay, Saklar Dinding Servo, & Remote AC Card
│   ├── timer_screen.dart       # Manajemen countdown timer, visual progress bar, & modal add timer
│   ├── scheduler_screen.dart   # Manajemen 10 slot jadwal harian NTP & auto-alternating helper
│   └── settings_screen.dart    # Konfigurasi IP, port aktif, kalibrasi servo, polaritas, OLED, & reset
│
├── services/
│   ├── api_service.dart        # HTTP Client REST API dengan timeout, retry, & error handling
│   └── storage_service.dart    # Wrapper SharedPreferences (IP server, tema, & kapabilitas lokal)
│
├── widgets/
│   ├── ac_remote_card.dart     # Kartu tactile modern pengontrol AC FLiFE / Gree IR
│   ├── device_target_chip.dart # Chip selector target (Relay, Switch, AC) untuk modal timer & sched
│   ├── relay_card.dart         # Kartu tactile interaktif Relay dengan optimistic state & gradients
│   ├── wall_switch_card.dart   # Kartu saklar tembok mekanis dengan tombol servo ON & OFF
│   └── status_badge.dart       # Badge status konektivitas, IP, & indikator sync di app bar
│
└── main.dart                   # Entry point aplikasi Flutter & MultiProvider initialization
```

### Rincian Modul:

#### 1. `constants/`
- [app_colors.dart](file:///c:/Nova/r_sync_app/lib/constants/app_colors.dart): Menyediakan konstanta warna statis untuk brand identity (Teal, Orange, Indigo, Emerald), status sistem (Success, Warning, Error), warna container, dan gradasi visual kartu relay.
- [app_theme.dart](file:///c:/Nova/r_sync_app/lib/constants/app_theme.dart): Mengonfigurasi `ThemeData` untuk Light Mode dan Dark Mode secara komprehensif, mencakup tema AppBar, Card, InputDecoration, Elevated/Outlined Button, Slider, Chip, BottomSheet, Dialog, dan NavigationBar dengan tipografi Google Font *Poppins*.

#### 2. `models/`
- [esp_capabilities.dart](file:///c:/Nova/r_sync_app/lib/models/esp_capabilities.dart): Memetakan respon dari `GET /api/capabilities`. Mengelola flag fitur dinamis seperti `acFeature`, `activeRelays`, `activeSwitches`, `oledConnected`, `relaysCount`, dan `switchesCount`. Dilengkapi metode `saveToLocal()` dan `loadFromLocal()` untuk *offline caching*.
- [esp_status.dart](file:///c:/Nova/r_sync_app/lib/models/esp_status.dart): Memetakan respon real-time dari `GET /api/status`. Menyimpan array relay, saklar, telemetri tegangan rail servo (`servoRailMv`, `servoRailMinMv`), antrean FIFO servo (`servoBusy`, `servoQueueLength`), daftar timer, jadwal harian, dan seluruh status AC (`acPower`, `acTemp`, `acMode`, `acFan`, `acSwingV`, `acSleep`, `acTurbo`, `acXFan`, `acLight`, `acIFeel`, `acDisplayTemp`).
- [schedule_job.dart](file:///c:/Nova/r_sync_app/lib/models/schedule_job.dart): Memetakan entri jadwal harian ESP32 v3.0.0. Menyimpan jam, menit, aksi (`ON`/`OFF`), status aktif (`enabled`), target AC (`targetAc`: 0=Abaikan, 1=ON, 2=OFF), serta array target relay dan saklar.
- [timer_job.dart](file:///c:/Nova/r_sync_app/lib/models/timer_job.dart): Memetakan status timer hitung mundur. Menghitung durasi sisa, status `isPaused`, `isRunning`, `isFinished`, persentase progres (`progress`), format waktu `HH:MM:SS`, dan target perangkat termasuk AC (`targetAc`).

#### 3. `providers/`
- [esp_provider.dart](file:///c:/Nova/r_sync_app/lib/providers/esp_provider.dart): Jantung state management aplikasi.
  - Mengelola siklus *polling loop* otomatis (setiap 2 detik saat online, 5 detik saat offline).
  - Melakukan *optimistic UI updates* saat pengguna menekan tombol relay, saklar, atau kontrol AC, lalu merekonsiliasi dengan respon server.
  - Menyediakan aksi lengkap: `toggleRelay`, `triggerSwitch`, `sendAcCommand`, `addTimer`, `controlTimer`, `updateServoConfig`, `testServo`, `setDisplayPage`, `setRelayPolarity`, `updateHardwareConfig`, dan `resetWifi`.
- [schedule_provider.dart](file:///c:/Nova/r_sync_app/lib/providers/schedule_provider.dart): Mengelola daftar 10 slot jadwal harian. Menangani penambahan, pengeditan, toggle status jadwal, serta pengiriman batch ke endpoint `POST /api/schedules`. Dilengkapi algoritma rekomendasi *auto-alternating* (misal jika slot sebelumnya ON, slot berikutnya otomatis direkomendasikan OFF).
- [theme_provider.dart](file:///c:/Nova/r_sync_app/lib/providers/theme_provider.dart): Mengelola pemilihan tema aplikasi (`ThemeMode.light` atau `ThemeMode.dark`) dan menyimpannya secara persisten ke SharedPreferences melalui `StorageService`.

#### 4. `services/`
- [api_service.dart](file:///c:/Nova/r_sync_app/lib/services/api_service.dart): Abstraksi komunikasi HTTP REST API ke ESP32.
  - Memiliki timeout default 4 detik dan normalisasi URL IP otomatis.
  - Menyediakan fungsi untuk seluruh 13 endpoint firmware ESP32 R-Sync.
- [storage_service.dart](file:///c:/Nova/r_sync_app/lib/services/storage_service.dart): Wrapper penyimpanan lokal `SharedPreferences` untuk menyimpan alamat IP ESP32 terakhir, tema pilihan, dan cache kapabilitas hardware.

#### 5. `widgets/`
- [ac_remote_card.dart](file:///c:/Nova/r_sync_app/lib/widgets/ac_remote_card.dart): Kartu pengontrol AC modern beranimasi. Menampilkan status daya, pengatur suhu (16–30°C), selector mode, segmented button kecepatan kipas, dropdown display suhu, dan 6 tombol kenyamanan (Swing, Turbo, Sleep, X-Fan, I-Feel, Light) dalam format grid 2x3 yang rapi.
- [relay_card.dart](file:///c:/Nova/r_sync_app/lib/widgets/relay_card.dart): Kartu interaktif untuk masing-masing Relay 1..4 dengan efek glow, indikator aktif, dan animasi transisi.
- [wall_switch_card.dart](file:///c:/Nova/r_sync_app/lib/widgets/wall_switch_card.dart): Kartu pengontrol saklar dinding mekanis dengan dua tombol terpisah: "TEKAN ON" (menggerakkan servo ON) dan "TEKAN OFF" (menggerakkan servo OFF).
- [device_target_chip.dart](file:///c:/Nova/r_sync_app/lib/widgets/device_target_chip.dart): Komponen chip selektor perangkat target (Relay 1..4, Saklar A..C, AC ON/OFF) yang digunakan pada dialog pembuatan timer dan jadwal.
- [status_badge.dart](file:///c:/Nova/r_sync_app/lib/widgets/status_badge.dart): Komponen pill badge di AppBar yang menampilkan alamat IP ESP32, indikator online/offline berwarna, jam sinkronisasi terakhir, dan tombol refresh cepat.

#### 6. `screens/`
- [dashboard_screen.dart](file:///c:/Nova/r_sync_app/lib/screens/dashboard_screen.dart): Halaman kontrol utama dengan fitur pull-to-refresh. Menampilkan deretan kartu Relay aktif, kartu Saklar Dinding aktif, dan kartu Remote AC Pintar. Menampilkan dialog koneksi cepat jika IP belum disetel.
- [timer_screen.dart](file:///c:/Nova/r_sync_app/lib/screens/timer_screen.dart): Halaman pemantauan dan pembuatan timer hitung mundur. Menampilkan kartu timer berjalan lengkap dengan progres bar, tombol jeda/lanjut/batal, serta modal pembuatan timer dengan selektor target multi-perangkat.
- [scheduler_screen.dart](file:///c:/Nova/r_sync_app/lib/screens/scheduler_screen.dart): Halaman manajemen 10 slot jadwal otomatis harian NTP. Memungkinkan pengeditan jam, menit, aksi, dan target perangkat dengan sinkronisasi batch ke ESP32.
- [settings_screen.dart](file:///c:/Nova/r_sync_app/lib/screens/settings_screen.dart): Halaman pengaturan menyeluruh:
  - Input & uji koneksi IP ESP32.
  - Port Hardware Aktif (Relay 1..4, Switch A..C, dan AC Port).
  - Kalibrasi sudut motor servo (Rest, Press, Duration, dan Fine-Tuning per-servo).
  - Diagnostik self-test servo & telemetri rail tegangan.
  - Pengaturan halaman layar OLED SSD1306 (0..3).
  - Toggle polaritas relay (Active LOW / Active HIGH).
  - Pemilihan tema Light / Dark mode.
  - Reset Wi-Fi ESP32 jarak jauh.

---

## 📡 Alur Komunikasi & Kontrak REST API ESP32

Aplikasi berkomunikasi langsung dengan firmware ESP32 di jaringan lokal:

| Endpoint | Method | Fungsi di Aplikasi Flutter | File Service Terkait |
| :--- | :--- | :--- | :--- |
| `/api/capabilities` | `GET` | Discovery jumlah relay, switch, AC, & OLED | `api_service.dart -> getCapabilities()` |
| `/api/status` | `GET` | Polling real-time status relay, switch, AC, timer, jadwal | `api_service.dart -> getStatus()` |
| `/api/relay` | `POST` | Saklar on/off Relay 1..4 | `api_service.dart -> setRelay()` |
| `/api/switch` | `POST` | Memicu servo Saklar Tembok A..C | `api_service.dart -> triggerSwitch()` |
| `/api/ac` | `POST` | Mengirim sinyal IR AC (Power, Temp, Mode, Fan, dll) | `api_service.dart -> sendAcCommand()` |
| `/api/relay/polarity`| `POST` | Mengubah Active LOW / Active HIGH | `api_service.dart -> setRelayPolarity()` |
| `/api/timer` | `POST` | Tambah, jeda, lanjut, batal, & hapus timer | `api_service.dart -> addTimer() / controlTimer()` |
| `/api/schedules` | `GET`/`POST`| Baca & simpan 10 slot jadwal harian | `api_service.dart -> getSchedules() / setSchedules()` |
| `/api/servo/config` | `POST` | Simpan kalibrasi sudut & durasi servo | `api_service.dart -> setServoConfig()` |
| `/api/servo/test` | `POST` | Uji coba fisik motor servo | `api_service.dart -> testServo()` |
| `/api/display` | `POST` | Ganti halaman layar OLED (0..3) | `api_service.dart -> setDisplayPage()` |
| `/api/hardware/config`| `GET`/`POST`| Konfigurasi port hardware aktif | `api_service.dart -> getHardwareConfig() / setHardwareConfig()` |
| `/api/wifi/reset` | `POST` | Reset Wi-Fi & buka captive portal | `api_service.dart -> resetWifi()` |

---

## ⚡ Mekanisme Optimistic UI & Keandalan Jaringan

1. **Optimistic UI Updates:**
   - Saat pengguna menekan kartu Relay, tombol Switch, atau pengatur AC, UI langsung memperbarui status secara visual seketika tanpa menunggu respon jaringan selesai (*zero perceived latency*).
   - Jika panggilan API gagal (misal koneksi terputus atau timeout), `EspProvider` secara otomatis membatalkan perubahan (*rollback*) ke status sebelumnya dan menampilkan notifikasi kesalahan via `SnackBar`.
2. **Polling Adaptif Non-Intrusif:**
   - Saat aplikasi dalam kondisi aktif dan online, data diperbarui setiap **2 detik**.
   - Jika koneksi terputus, frekuensi polling otomatis diturunkan menjadi setiap **5 detik** untuk menghemat baterai perangkat dan mengurangi beban lalu lintas jaringan.
3. **Penyimpanan Lokal Mandiri:**
   - SharedPreferences menyimpan cache kapabilitas terakhir sehingga antarmuka tetap konsisten bahkan saat ESP32 sedang offline atau dalam proses reboot.

---

## 🚀 Panduan Menjalankan, Pengujian, & Build

### 1. Menjalankan Mode Development:
```powershell
# Jalankan di Android Emulator / Device
flutter run -d android

# Jalankan di Desktop Windows
flutter run -d windows

# Jalankan di Browser Web (Chrome)
flutter run -d chrome
```

### 2. Menjalankan Automated Unit & Widget Test:
Seluruh test suite widget telah diselaraskan dengan parameter hardware terbaru (termasuk modul AC):
```powershell
flutter test
```

### 3. Memeriksa Analisis Statis Kode (*Linting*):
```powershell
flutter analyze
```

### 4. Build Paket Rilis Produksi:
```powershell
# Build APK Android Rilis
flutter build apk --release

# Build Aplikasi Desktop Windows
flutter build windows --release

# Build Web Application
flutter build web --release
```

---

*Dikembangkan dengan standar rekayasa Flutter terbaik untuk ekosistem open-source **R-Sync** oleh **Zenalghi** ([Aplikasi Flutter Client](https://github.com/Zenalghi/r_sync_app) • [Firmware ESP32 Local Server](https://github.com/Zenalghi/relay-local-server) • [Spesifikasi API AI Tool Calling](file:///c:/Nova/relay-local-server/R-Sync_API_TOOL_CALLING.md)).*
