import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';
import '../widgets/relay_card.dart';

/// Main Dashboard screen with real-time relay controls,
/// quick master actions, and connection status overview.
class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToSettings;

  const DashboardScreen({
    super.key,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final espProvider = context.watch<EspProvider>();
    final status = espProvider.status;
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
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                            'STATUS PERANGKAT ESP32',
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Relay Channels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kontrol Saklar Relay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '2 Channel Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Relay 1 Card
            RelayCard(
              channel: 1,
              title: 'Relay 1 (Channel A)',
              subtitle: 'Kendali beban utama',
              isOn: status.relay1,
              isConnected: isConnected,
              nextJob: status.getNextActiveJob(1),
              onToggle: () => espProvider.toggleRelay(1),
            ),

            const SizedBox(height: 16),

            // Relay 2 Card
            RelayCard(
              channel: 2,
              title: 'Relay 2 (Channel B)',
              subtitle: 'Kendali beban sekunder',
              isOn: status.relay2,
              isConnected: isConnected,
              nextJob: status.getNextActiveJob(2),
              onToggle: () => espProvider.toggleRelay(2),
            ),

            const SizedBox(height: 24),

            // Master Quick Controls
            Text(
              'Aksi Cepat Sekaligus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isConnected
                        ? () async {
                            await espProvider.setRelayState(1, true);
                            await espProvider.setRelayState(2, true);
                          }
                        : null,
                    icon: const Icon(Icons.flash_on_rounded,
                        color: AppColors.teal, size: 18),
                    label: const Text('Nyalakan Semua'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.teal.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isConnected
                        ? () async {
                            await espProvider.setRelayState(1, false);
                            await espProvider.setRelayState(2, false);
                          }
                        : null,
                    icon: const Icon(Icons.flash_off_rounded,
                        color: AppColors.orange, size: 18),
                    label: const Text('Matikan Semua'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.orange.withValues(alpha: 0.5),
                      ),
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
