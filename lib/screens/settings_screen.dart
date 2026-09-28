// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';
import '../providers/theme_provider.dart';

/// Settings screen for configuring ESP32 local IP address,
/// Servo Calibration (Rest & Press Angles), Relay Active LOW/HIGH polarity,
/// Light/Dark theme switching, background polling interval, and device diagnostics.
class SettingsScreen extends StatefulWidget {
  final int refreshToken;

  const SettingsScreen({super.key, this.refreshToken = 0});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  bool _isTesting = false;
  bool? _testResult;
  String? _testMessage;
  String _appVersion = '1.0.0';
  late int _restAngle;
  late int _pressAngle;
  late List<int> _pressAngles;
  late int _pressDurationMs;
  int _selectedSwitchTab = 0;
  bool _isSavingServoConfig = false;
  bool _isRefreshingSettings = false;
  List<bool> _activeRelays = [true, true, true, true];
  List<bool> _activeSwitches = [true, true, true];
  bool _isSavingHwConfig = false;

  @override
  void initState() {
    super.initState();
    final espProvider = context.read<EspProvider>();
    _ipController = TextEditingController(text: espProvider.espIp);
    _restAngle = espProvider.status.restAngle;
    _pressAngle = espProvider.status.pressAngle;
    _pressAngles = List<int>.from(espProvider.status.pressAngles);
    while (_pressAngles.length < 6) {
      _pressAngles.add(_pressAngle);
    }
    _pressDurationMs = espProvider.status.pressDurationMs;
    _activeRelays = List<bool>.from(espProvider.capabilities.activeRelays);
    _activeSwitches = List<bool>.from(espProvider.capabilities.activeSwitches);
    _loadAppVersion();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshSettingsFromEsp();
        }
      });
    }
  }

  Future<void> _refreshSettingsFromEsp() async {
    if (_isRefreshingSettings) return;
    setState(() => _isRefreshingSettings = true);
    final espProvider = context.read<EspProvider>();
    await espProvider.refreshStatus();
    if (espProvider.isConnected) {
      _syncServoConfigFromStatus();
    }
    if (mounted) setState(() => _isRefreshingSettings = false);
  }

  void _syncServoConfigFromStatus() {
    if (!mounted) return;
    final espProvider = context.read<EspProvider>();
    final status = espProvider.status;
    final caps = espProvider.capabilities;
    setState(() {
      _restAngle = status.restAngle;
      _pressAngle = status.pressAngle;
      _pressAngles = List<int>.from(status.pressAngles);
      while (_pressAngles.length < 6) {
        _pressAngles.add(_pressAngle);
      }
      _pressDurationMs = status.pressDurationMs;
      _activeRelays = List<bool>.from(caps.activeRelays);
      _activeSwitches = List<bool>.from(caps.activeSwitches);
    });
  }

  Future<void> _saveHardwareConfig() async {
    setState(() => _isSavingHwConfig = true);
    final espProvider = context.read<EspProvider>();
    final success = await espProvider.setHardwareConfig(
      relays: _activeRelays,
      switches: _activeSwitches,
    );
    if (mounted) {
      setState(() => _isSavingHwConfig = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Konfigurasi Port Hardware Berhasil Disimpan!'
                : 'Gagal menyimpan konfigurasi hardware ke ESP32.',
          ),
          backgroundColor: success ? AppColors.teal : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        setState(() {
          _appVersion = info.version;
        });
      }
    } catch (_) {}
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
    final ipChanged = newIp != espProvider.espIp;
    await espProvider.setEspIp(newIp);
    // setEspIp only refetches when the address actually changed
    if (!ipChanged) {
      await espProvider.refreshStatus();
    }
    _syncServoConfigFromStatus();

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
      _syncServoConfigFromStatus();
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

  Future<void> _saveServoConfig() async {
    setState(() => _isSavingServoConfig = true);
    final espProvider = context.read<EspProvider>();
    final success = await espProvider.setServoConfig(
      restAngle: _restAngle,
      pressAngle: _pressAngle,
      pressDurationMs: _pressDurationMs,
      pressAngles: _pressAngles,
    );
    if (mounted) {
      setState(() => _isSavingServoConfig = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Kalibrasi 6 Servo Berhasil Disimpan di ESP32!'
                : 'Gagal menyimpan kalibrasi servo.',
          ),
          backgroundColor: success ? AppColors.teal : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                  : 'Gagal mengubah polaritas relay: '
                        '${espProvider.relayPolarityError ?? 'ESP32 tidak merespons.'}',
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
    final caps = espProvider.capabilities;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshSettingsFromEsp,
        color: AppColors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  color: AppColors.themedBorder(
                    AppColors.teal,
                    Theme.of(context).brightness,
                  ),
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
                              : const Icon(
                                  Icons.network_check_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _isTesting ? 'Menguji...' : 'Tes Koneksi',
                          ),
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
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: espProvider.isConnected
                        ? _confirmResetWifi
                        : null,
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

            if (!espProvider.isConnected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hubungkan smartphone ke ESP32 untuk membuka pengaturan Port Hardware, Polaritas Relay, dan Kalibrasi Servo.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Section: Port Hardware Aktif (Relay & Switch) - Only visible when connected
            if (espProvider.isConnected) ...[
              _buildSectionHeader(
                icon: Icons.developer_board_rounded,
                title: 'Port Hardware Aktif (Relay & Switch)',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.themedBorder(
                      AppColors.teal,
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PORT RELAY AKTIF',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(4, (i) {
                        final isActive =
                            i < _activeRelays.length && _activeRelays[i];
                        return FilterChip(
                          label: Text('Relay ${i + 1}'),
                          selected: isActive,
                          selectedColor: AppColors.teal.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.teal,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.teal
                                : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (i < _activeRelays.length) {
                                _activeRelays[i] = val;
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PORT SWITCH AKTIF (SERVO)',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(3, (i) {
                        final names = ['A', 'B', 'C'];
                        final name = i < names.length ? names[i] : '${i + 1}';
                        final isActive =
                            i < _activeSwitches.length && _activeSwitches[i];
                        return FilterChip(
                          label: Text('Switch $name'),
                          selected: isActive,
                          selectedColor: AppColors.indigo.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppColors.indigo,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.indigo
                                : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (i < _activeSwitches.length) {
                                _activeSwitches[i] = val;
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: espProvider.isConnected && !_isSavingHwConfig
                          ? _saveHardwareConfig
                          : null,
                      icon: _isSavingHwConfig
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Simpan Konfigurasi Port'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Section: Relay Hardware Polarity Control - Only visible when connected AND has active relays
            if (espProvider.isConnected && caps.relaysCount > 0) ...[
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
                    color: AppColors.themedBorder(
                      AppColors.orange,
                      Theme.of(context).brightness,
                    ),
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
                            onTap: espProvider.isConnected
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
                            onTap: espProvider.isConnected
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
            ],

            // Section: Servo Calibration (Rest & Press Angle) - Only visible when connected AND has active switches
            if (espProvider.isConnected && caps.switchesCount > 0) ...[
              _buildSectionHeader(
                icon: Icons.tune_rounded,
                title: 'Kalibrasi Sudut Servo Switch',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.themedBorder(
                      AppColors.indigo,
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Switch Selection Tabs
                    Row(
                      children: List.generate(caps.switchesCount, (idx) {
                        final isSelected = _selectedSwitchTab == idx;
                        final names = ['A', 'B', 'C'];
                        final swName = idx < names.length
                            ? names[idx]
                            : '${idx + 1}';
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: idx < caps.switchesCount - 1 ? 8.0 : 0.0,
                            ),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedSwitchTab = idx),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.teal.withValues(alpha: 0.18)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              )),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.teal
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Switch $swName',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.teal
                                          : (isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    // Active Switch Servo Pair (ON & OFF)
                    Builder(
                      builder: (ctx) {
                        final sw = _selectedSwitchTab.clamp(
                          0,
                          caps.switchesCount - 1,
                        );
                        final servoOnIdx = sw * 2;
                        final servoOffIdx = sw * 2 + 1;
                        // final gpioPins = const [14, 27, 26, 25, 33, 32];
                        // final pinOn = servoOnIdx < gpioPins.length ? gpioPins[servoOnIdx] : 0;
                        // final pinOff = servoOffIdx < gpioPins.length ? gpioPins[servoOffIdx] : 0;
                        final onAngle = _pressAngles.length > servoOnIdx
                            ? _pressAngles[servoOnIdx]
                            : _pressAngle;
                        final offAngle = _pressAngles.length > servoOffIdx
                            ? _pressAngles[servoOffIdx]
                            : _pressAngle;

                        return Column(
                          children: [
                            // Servo ON Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : AppColors.teal.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.teal.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.teal.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'SERVO ON',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.teal,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(width: 8),
                                          // Text(
                                          //   'GPIO $pinOn',
                                          //   style: TextStyle(
                                          //     fontSize: 11,
                                          //     color: isDark
                                          //         ? AppColors.darkTextMuted
                                          //         : AppColors.lightTextMuted,
                                          //     fontWeight: FontWeight.w600,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '$onAngle°',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.teal,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 28,
                                            child: OutlinedButton(
                                              onPressed: espProvider.isConnected
                                                  ? () => espProvider
                                                        .triggerServoTest(
                                                          servoIdx: servoOnIdx,
                                                        )
                                                  : null,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.teal,
                                                side: const BorderSide(
                                                  color: AppColors.teal,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Tes ON',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: onAngle.toDouble(),
                                    min: 0,
                                    max: 180,
                                    divisions: 180,
                                    activeColor: AppColors.teal,
                                    label: '$onAngle°',
                                    onChanged: (val) {
                                      setState(() {
                                        _pressAngles[servoOnIdx] = val.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Servo OFF Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : AppColors.orange.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.orange.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.orange
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'SERVO OFF',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.orange,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(width: 8),
                                          // Text(
                                          //   'GPIO $pinOff',
                                          //   style: TextStyle(
                                          //     fontSize: 11,
                                          //     color: isDark
                                          //         ? AppColors.darkTextMuted
                                          //         : AppColors.lightTextMuted,
                                          //     fontWeight: FontWeight.w600,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '$offAngle°',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 28,
                                            child: OutlinedButton(
                                              onPressed: espProvider.isConnected
                                                  ? () => espProvider
                                                        .triggerServoTest(
                                                          servoIdx: servoOffIdx,
                                                        )
                                                  : null,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.orange,
                                                side: const BorderSide(
                                                  color: AppColors.orange,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Tes OFF',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: offAngle.toDouble(),
                                    min: 0,
                                    max: 180,
                                    divisions: 180,
                                    activeColor: AppColors.orange,
                                    label: '$offAngle°',
                                    onChanged: (val) {
                                      setState(() {
                                        _pressAngles[servoOffIdx] = val.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Global Rest Angle Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rest Angle (Posisi Netral Standby):',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_restAngle°',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _restAngle.toDouble(),
                      min: 0,
                      max: 180,
                      divisions: 180,
                      activeColor: AppColors.teal,
                      label: '$_restAngle°',
                      onChanged: (val) =>
                          setState(() => _restAngle = val.round()),
                    ),

                    const SizedBox(height: 10),

                    // Press Duration Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Durasi Tekanan (Hold Time):',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_pressDurationMs}ms',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _pressDurationMs.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 38,
                      activeColor: AppColors.indigo,
                      label: '${_pressDurationMs}ms',
                      onChanged: (val) =>
                          setState(() => _pressDurationMs = val.round()),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: espProvider.isConnected
                                ? () => espProvider.triggerServoTest()
                                : null,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: const Text('Tes Semua'),
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
                            onPressed:
                                espProvider.isConnected && !_isSavingServoConfig
                                ? _saveServoConfig
                                : null,
                            icon: _isSavingServoConfig
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                  ),
                            label: const Text('Simpan'),
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
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            const SizedBox(height: 12),

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
                  color: AppColors.themedBorder(
                    AppColors.emerald,
                    Theme.of(context).brightness,
                  ),
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
                        onTap: () =>
                            themeProvider.setThemeMode(ThemeMode.light),
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
                        onTap: () =>
                            themeProvider.setThemeMode(ThemeMode.system),
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
                  color: AppColors.themedBorder(
                    AppColors.tealLight,
                    Theme.of(context).brightness,
                  ),
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
                            DropdownMenuItem(
                              value: 10,
                              child: Text('10 Detik'),
                            ),
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
                  color: AppColors.themedBorder(
                    AppColors.indigo,
                    Theme.of(context).brightness,
                  ),
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
                          'Smart Relay & Servo Wall Switch Automation System',
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
    final accent = isActiveLowOption ? AppColors.teal : AppColors.orange;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.themedBorder(accent, Theme.of(context).brightness)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? accent
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
                    ? accent
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
}
