// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';
import '../widgets/relay_card.dart';
import '../widgets/wall_switch_card.dart';

/// Main Dashboard screen with real-time relay and wall switch controls,
/// quick master actions, and connection status overview.
class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToSettings;

  const DashboardScreen({super.key, required this.onNavigateToSettings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final espProvider = context.watch<EspProvider>();
    final status = espProvider.status;
    final caps = espProvider.capabilities;
    final isConnected = espProvider.isConnected;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => espProvider.refreshStatus(),
        color: AppColors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // ESP32 Hardware Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.themedBorder(
                    isConnected ? AppColors.teal : AppColors.indigo,
                    Theme.of(context).brightness,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isConnected
                                ? Icons.memory_rounded
                                : Icons.wifi_off_rounded,
                            size: 20,
                            color: isConnected
                                ? (isDark
                                      ? AppColors.tealLight
                                      : AppColors.teal)
                                : AppColors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            caps.deviceName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.tealLight
                                  : AppColors.tealDark,
                            ),
                          ),
                        ],
                      ),
                      if (espProvider.isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.teal,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isConnected
                                        ? AppColors.emerald
                                        : AppColors.orange)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? AppColors.emerald
                                      : AppColors.orange,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isConnected ? 'Terhubung' : 'Belum Konek',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isConnected
                                      ? AppColors.emerald
                                      : AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // IP Info
                      Expanded(
                        child: _buildInfoItem(
                          context: context,
                          icon: Icons.lan_rounded,
                          label: 'IP Lokal',
                          value: isConnected && status.ip.isNotEmpty
                              ? status.ip
                              : espProvider.espIp,
                          color: AppColors.teal,
                        ),
                      ),
                      // WiFi Info
                      Expanded(
                        child: _buildInfoItem(
                          context: context,
                          icon: Icons.wifi_rounded,
                          label: 'Status Wi-Fi',
                          value: isConnected ? status.wifi : 'Terputus',
                          color: isConnected
                              ? AppColors.emerald
                              : AppColors.error,
                        ),
                      ),
                      // NTP Clock
                      Expanded(
                        child: _buildInfoItem(
                          context: context,
                          icon: Icons.access_time_rounded,
                          label: 'Waktu ESP',
                          value: isConnected && status.isTimeSynced
                              ? (status.time.split(' ').length > 1
                                    ? status.time.split(' ')[1]
                                    : status.time)
                              : '-',
                          color: AppColors.indigo,
                        ),
                      ),
                    ],
                  ),
                  if (espProvider.isOledConnected) ...[
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    const SizedBox(height: 12),

                    // OLED Display Controller Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.smart_display_rounded,
                            size: 18,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAYAR OLED FISIK ESP32',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                () {
                                  switch (status.displayPage) {
                                    case 0:
                                      return 'Hal 1: Status Perangkat';
                                    case 1:
                                      return 'Hal 2: Jadwal Otomatis';
                                    case 2:
                                      return 'Hal 3: Daftar Timer';
                                    default:
                                      return 'Halaman OLED #${status.displayPage + 1}';
                                  }
                                }(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => espProvider.setDisplayPage(
                            (status.displayPage + 1) % 3,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text(
                            'Ganti Hal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            foregroundColor: AppColors.orange,
                            backgroundColor: AppColors.orange.withValues(
                              alpha: 0.12,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Disconnected State: Onboarding Guide
            if (!isConnected) ...[
              _buildDisconnectedOnboarding(context, isDark, espProvider),
            ] else ...[
              // Connected State: Dynamically show only ACTIVE hardware
              const SizedBox(height: 24),

              // Section: Relay Channels
              if (caps.relaysCount > 0) ...[
                () {
                  final activeRelays = caps.activeRelayChannels;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Kontrol Relay (${activeRelays.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCompactAction(
                                icon: Icons.flash_on_rounded,
                                label: 'Semua ON',
                                color: AppColors.teal,
                                onPressed: () async {
                                  for (final r in activeRelays) {
                                    if (!status.getRelayState(r)) {
                                      await espProvider.toggleRelay(r);
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildCompactAction(
                                icon: Icons.flash_off_rounded,
                                label: 'Semua OFF',
                                color: AppColors.orange,
                                onPressed: () async {
                                  for (final r in activeRelays) {
                                    if (status.getRelayState(r)) {
                                      await espProvider.toggleRelay(r);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dynamic Active Relay Cards
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeRelays.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ch = activeRelays[index];
                          return RelayCard(
                            channel: ch,
                            title: 'Relay $ch',
                            subtitle: 'Beban relay channel $ch',
                            isOn: status.getRelayState(ch),
                            isConnected: isConnected,
                            nextJob: status.getNextActiveJobForRelay(ch),
                            onToggle: () => espProvider.toggleRelay(ch),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }(),
              ],

              // Section: Wall Switches (Servos)
              if (caps.switchesCount > 0) ...[
                () {
                  final activeSwitches = caps.activeSwitchIndices;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Switch Servo (${activeSwitches.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCompactAction(
                                icon: Icons.build_rounded,
                                label: 'Tes',
                                color: AppColors.indigo,
                                onPressed: () => espProvider.triggerServoTest(),
                              ),
                              const SizedBox(width: 6),
                              _buildCompactAction(
                                icon: Icons.flash_on_rounded,
                                label: 'Semua ON',
                                color: AppColors.teal,
                                onPressed: () async {
                                  for (final s in activeSwitches) {
                                    await espProvider.triggerSwitchAction(
                                      s,
                                      true,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildCompactAction(
                                icon: Icons.flash_off_rounded,
                                label: 'Semua OFF',
                                color: AppColors.orange,
                                onPressed: () async {
                                  for (final s in activeSwitches) {
                                    await espProvider.triggerSwitchAction(
                                      s,
                                      false,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Live Servo Busy / Queue Banner
                      if (status.servoBusy || status.servoQueueLength > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.indigo.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.indigo,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  status.servoBusy
                                      ? 'Servo sedang bergerak...'
                                      : 'Antrean servo: ${status.servoQueueLength} gerakan',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.indigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Dynamic Switch Cards
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeSwitches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sIdx = activeSwitches[index];
                          final names = ['A', 'B', 'C'];
                          final swName = sIdx < names.length
                              ? names[sIdx]
                              : '${sIdx + 1}';
                          return WallSwitchCard(
                            switchIdx: sIdx,
                            title: 'Switch $swName',
                            subtitle: '2 Servo (ON/OFF)',
                            isConnected: isConnected,
                            onPressOn: () =>
                                espProvider.triggerSwitchAction(sIdx, true),
                            onPressOff: () =>
                                espProvider.triggerSwitchAction(sIdx, false),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }(),
              ],

              // Connected but 0 active hardware
              if (caps.relaysCount == 0 && caps.switchesCount == 0) ...[
                _buildNoActiveHardwareBanner(context, isDark),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedOnboarding(
    BuildContext context,
    bool isDark,
    EspProvider espProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.themedBorder(
            AppColors.teal,
            Theme.of(context).brightness,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Visual Icon Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.2),
                  AppColors.indigo.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.sensors_off_rounded,
              color: AppColors.teal,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'ESP32 Belum Terhubung',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Aplikasi siap mengontrol Relay, Saklar Tembok, dan Layar OLED. Hubungkan smartphone ke jaringan ESP32 untuk mendeteksi perangkat secara otomatis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // 3-Step Quick Guide
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildGuideStep(
                  isDark: isDark,
                  stepNumber: '1',
                  text: 'Nyalakan modul hardware ESP32 Anda.',
                ),
                const SizedBox(height: 10),
                _buildGuideStep(
                  isDark: isDark,
                  stepNumber: '2',
                  text:
                      'Sambungkan Wi-Fi smartphone ke Access Point "R-Sync" atau router lokal yang sama.',
                ),
                const SizedBox(height: 10),
                _buildGuideStep(
                  isDark: isDark,
                  stepNumber: '3',
                  text:
                      'Buka menu Pengaturan untuk memeriksa atau menyesuaikan alamat IP (default: 192.168.4.1).',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // CTAs
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigateToSettings,
                  icon: const Icon(Icons.settings_ethernet_rounded, size: 18),
                  label: const Text(
                    'Atur Koneksi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => espProvider.refreshStatus(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveHardwareBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.themedBorder(
            AppColors.orange,
            Theme.of(context).brightness,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.power_off_rounded,
            color: AppColors.orange,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak Ada Port Hardware Aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Semua port Relay dan Saklar dinonaktifkan di konfigurasi hardware. Aktifkan port yang Anda gunakan di menu Pengaturan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNavigateToSettings,
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text(
              'Buka Pengaturan Port',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
    );
  }

  Widget _buildGuideStep({
    required bool isDark,
    required String stepNumber,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.teal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, size: 17),
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        maximumSize: const Size(36, 36),
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
