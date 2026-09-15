//lib\screens\settings_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';
import '../providers/theme_provider.dart';

/// Settings screen for configuring ESP32 local IP address,
/// Relay Active LOW/HIGH polarity, Light/Dark theme switching,
/// background polling interval, and device diagnostics.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  bool _isTesting = false;
  bool? _testResult;
  String? _testMessage;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    final currentIp = context.read<EspProvider>().espIp;
    _ipController = TextEditingController(text: currentIp);
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        setState(() {
          _appVersion = info.version;
        });
      }
    } catch (_) {
      // Fallback stays as '1.0.0'
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _saveIp() async {
    final newIp = _ipController.text.trim();
    if (newIp.isEmpty) return;

    final espProvider = context.read<EspProvider>();
    await espProvider.setEspIp(newIp);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('IP ESP32 diperbarui ke $newIp'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final ipToTest = _ipController.text.trim();
    if (ipToTest.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testMessage = null;
    });

    final espProvider = context.read<EspProvider>();
    final stopwatch = Stopwatch()..start();
    final isOk = await espProvider.testConnection(ipToTest);
    stopwatch.stop();

    if (isOk) {
      await espProvider.setEspIp(ipToTest);
    }

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = isOk;
        _testMessage = isOk
            ? 'Terhubung & IP Tersimpan! Respon ${stopwatch.elapsedMilliseconds} ms'
            : 'Gagal terhubung ke $ipToTest. Cek Wi-Fi & IP.';
      });
    }
  }

  Future<void> _confirmChangePolarity(bool targetActiveLow) async {
    final espProvider = context.read<EspProvider>();
    if (espProvider.status.activeLow == targetActiveLow) return;

    final messenger = ScaffoldMessenger.of(context);
    final targetText = targetActiveLow ? 'Active LOW' : 'Active HIGH';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(child: Text('Ubah Polaritas ke $targetText?')),
          ],
        ),
        content: Text(
          'Mengubah polaritas logika relay ke $targetText akan mematikan (OFF) semua sakelar relay secara otomatis demi keamanan hardware.\n\nLanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await espProvider.setRelayPolarity(targetActiveLow);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Polaritas relay berhasil diubah ke $targetText!'
                  : 'Gagal mengubah polaritas relay pada ESP32.',
            ),
            backgroundColor: success ? AppColors.teal : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmResetWifi() async {
    final espProvider = context.read<EspProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_protected_setup_rounded, color: AppColors.orange),
            SizedBox(width: 10),
            Expanded(child: Text('Reset Wi-Fi ESP32?')),
          ],
        ),
        content: const Text(
          'ESP32 akan menghapus kredensial Wi-Fi lama dan membuka Access Point "R-Sync" (192.168.4.1) untuk dikonfigurasi ke jaringan Wi-Fi baru.\n\nPerangkat akan restart otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset & Buka Portal'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await espProvider.resetWifi();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Perintah reset terkirim! Hubungkan HP ke Wi-Fi "R-Sync" (192.168.4.1).'
                  : 'Gagal mengirim perintah reset ke ESP32.',
            ),
            backgroundColor: ok ? AppColors.orange : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final espProvider = context.watch<EspProvider>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: ESP32 Device IP Configuration
          _buildSectionHeader(
            icon: Icons.router_rounded,
            title: 'Koneksi Perangkat ESP32',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ALAMAT IP / HOSTNAME ESP32',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _ipController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 192.168.4.1 atau 192.168.1.50',
                    prefixIcon: const Icon(Icons.lan_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.check_rounded,
                        color: AppColors.teal,
                      ),
                      tooltip: 'Simpan IP',
                      onPressed: _saveIp,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Connection Test Feedback Banner
                if (_testResult != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _testResult!
                          ? AppColors.emerald.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testResult!
                            ? AppColors.emerald
                            : AppColors.error,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testResult!
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 18,
                          color: _testResult!
                              ? AppColors.emerald
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testMessage ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _testResult!
                                  ? AppColors.emerald
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal,
                                ),
                              )
                            : const Icon(Icons.network_check_rounded, size: 18),
                        label: Text(_isTesting ? 'Menguji...' : 'Tes Koneksi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          side: const BorderSide(color: AppColors.teal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveIp,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Simpan IP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: espProvider.isConnected ? _confirmResetWifi : null,
                  icon: const Icon(
                    Icons.wifi_protected_setup_rounded,
                    size: 18,
                  ),
                  label: const Text('Pindah Wi-Fi / Buka Portal ESP32'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: BorderSide(
                      color: espProvider.isConnected
                          ? AppColors.orange
                          : (isDark
                                ? AppColors.darkBorder
                                : Colors.grey.shade400),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 2: Relay Hardware Polarity Control (Active LOW vs Active HIGH)
          _buildSectionHeader(
            icon: Icons.electric_bolt_rounded,
            title: 'Konfigurasi Polaritas Relay',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LOGIKA TRIGGER HARDWARE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    if (espProvider.isChangingPolarity)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.teal,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildPolarityOption(
                        title: 'Active LOW',
                        subtitle: 'ON = LOW (0V)\nOFF = HIGH (3.3V)',
                        icon: Icons.arrow_downward_rounded,
                        isActiveLowOption: true,
                        currentActiveLow: espProvider.status.activeLow,
                        onTap:
                            espProvider.isConnected &&
                                !espProvider.isChangingPolarity
                            ? () => _confirmChangePolarity(true)
                            : null,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPolarityOption(
                        title: 'Active HIGH',
                        subtitle: 'ON = HIGH (3.3V)\nOFF = LOW (0V)',
                        icon: Icons.arrow_upward_rounded,
                        isActiveLowOption: false,
                        currentActiveLow: espProvider.status.activeLow,
                        onTap:
                            espProvider.isConnected &&
                                !espProvider.isChangingPolarity
                            ? () => _confirmChangePolarity(false)
                            : null,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 3: Physical OLED Display Control
          _buildSectionHeader(
            icon: Icons.smart_display_rounded,
            title: 'Layar OLED Perangkat',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PILIHAN HALAMAN LAYAR FISIK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    if (espProvider.isSwitchingDisplay)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildOledPageOption(
                        title: 'Halaman 1: Status',
                        subtitle: 'WiFi, Jam, Relay',
                        icon: Icons.info_outline_rounded,
                        pageIndex: 0,
                        currentPage: espProvider.status.displayPage,
                        onTap:
                            espProvider.isConnected &&
                                !espProvider.isSwitchingDisplay
                            ? () => espProvider.setDisplayPage(0)
                            : null,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildOledPageOption(
                        title: 'Halaman 2: Jadwal',
                        subtitle: 'Daftar Scheduler',
                        icon: Icons.calendar_month_rounded,
                        pageIndex: 1,
                        currentPage: espProvider.status.displayPage,
                        onTap:
                            espProvider.isConnected &&
                                !espProvider.isSwitchingDisplay
                            ? () => espProvider.setDisplayPage(1)
                            : null,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 4: Appearance & Theme
          _buildSectionHeader(
            icon: Icons.palette_rounded,
            title: 'Tampilan & Tema',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODE TEMA APLIKASI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _buildThemeOption(
                      title: 'Terang',
                      icon: Icons.light_mode_rounded,
                      mode: ThemeMode.light,
                      currentMode: themeProvider.themeMode,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildThemeOption(
                      title: 'Gelap',
                      icon: Icons.dark_mode_rounded,
                      mode: ThemeMode.dark,
                      currentMode: themeProvider.themeMode,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildThemeOption(
                      title: 'Sistem',
                      icon: Icons.brightness_auto_rounded,
                      mode: ThemeMode.system,
                      currentMode: themeProvider.themeMode,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 5: Synchronization & Polling
          _buildSectionHeader(
            icon: Icons.sync_rounded,
            title: 'Sinkronisasi & Pembaruan',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembaruan Otomatis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cek status relay\ndan waktu ESP di background',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: espProvider.autoRefresh,
                      onChanged: (val) => espProvider.setAutoRefresh(val),
                      activeThumbColor: AppColors.teal,
                    ),
                  ],
                ),
                if (espProvider.autoRefresh) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interval Polling',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      DropdownButton<int>(
                        value: espProvider.pollInterval,
                        underline: const SizedBox.shrink(),
                        dropdownColor: isDark
                            ? AppColors.darkSurface
                            : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('2 Detik')),
                          DropdownMenuItem(value: 3, child: Text('3 Detik')),
                          DropdownMenuItem(value: 5, child: Text('5 Detik')),
                          DropdownMenuItem(value: 10, child: Text('10 Detik')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            espProvider.setPollInterval(val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 6: Device & App Info
          _buildSectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icons/ico.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.device_hub_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'R-Sync Relay Controller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Versi $_appVersion',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Smart Relay Automation & Control System',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPolarityOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActiveLowOption,
    required bool currentActiveLow,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final isSelected = currentActiveLow == isActiveLowOption;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.teal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.teal
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.teal
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = currentMode == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.teal.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.teal : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.teal
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade600),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.teal
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOledPageOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required int pageIndex,
    required int currentPage,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final isSelected = currentPage == pageIndex;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.orange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.orange
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.orange
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
