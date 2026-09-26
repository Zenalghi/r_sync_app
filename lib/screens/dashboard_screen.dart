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
            // Connection alert banner if offline
            if (!isConnected)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.error,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESP32 Tidak Terhubung',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pastikan smartphone terhubung ke Wi-Fi ESP32 atau atur IP di Pengaturan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onNavigateToSettings,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text('Pengaturan'),
                    ),
                  ],
                ),
              ),

            // ESP32 Hardware Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.themedBorder(
                    AppColors.indigo,
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
                            Icons.memory_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.tealLight
                                : AppColors.teal,
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
                          value: isConnected ? status.wifi : 'Offline',
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
                              : 'Syncing...',
                          color: AppColors.indigo,
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
                              'Halaman OLED #${status.displayPage + 1}',
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
                        onPressed: isConnected
                            ? () => espProvider.setDisplayPage(
                                (status.displayPage + 1) % 4,
                              )
                            : null,
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
              ),
            ),

            const SizedBox(height: 24),

            // Section: Relay Channels
            if (caps.relaysCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Kontrol Relay (${caps.relaysCount})',
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
                        onPressed: isConnected
                            ? () async {
                                for (int r = 1; r <= caps.relaysCount; r++) {
                                  if (!status.getRelayState(r)) {
                                    await espProvider.toggleRelay(r);
                                  }
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactAction(
                        icon: Icons.flash_off_rounded,
                        label: 'Semua OFF',
                        color: AppColors.orange,
                        onPressed: isConnected
                            ? () async {
                                for (int r = 1; r <= caps.relaysCount; r++) {
                                  if (status.getRelayState(r)) {
                                    await espProvider.toggleRelay(r);
                                  }
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dynamic Relay Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: caps.relaysCount,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ch = index + 1;
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

            // Section: Wall Switches (Servos)
            if (caps.switchesCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Switch Servo (${caps.switchesCount})',
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
                        onPressed: isConnected
                            ? () => espProvider.triggerServoTest()
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactAction(
                        icon: Icons.flash_on_rounded,
                        label: 'Semua ON',
                        color: AppColors.teal,
                        onPressed: isConnected
                            ? () async {
                                for (int s = 0; s < caps.switchesCount; s++) {
                                  await espProvider.triggerSwitchAction(
                                    s,
                                    true,
                                  );
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactAction(
                        icon: Icons.flash_off_rounded,
                        label: 'Semua OFF',
                        color: AppColors.orange,
                        onPressed: isConnected
                            ? () async {
                                for (int s = 0; s < caps.switchesCount; s++) {
                                  await espProvider.triggerSwitchAction(
                                    s,
                                    false,
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dynamic Switch Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: caps.switchesCount,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final names = ['A', 'B', 'C'];
                  final swName = index < names.length
                      ? names[index]
                      : '${index + 1}';
                  return WallSwitchCard(
                    switchIdx: index,
                    title: 'Switch $swName',
                    subtitle: '2 Servo (ON/OFF)',
                    isConnected: isConnected,
                    onPressOn: () =>
                        espProvider.triggerSwitchAction(index, true),
                    onPressOff: () =>
                        espProvider.triggerSwitchAction(index, false),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
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
