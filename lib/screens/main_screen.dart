import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';
import '../widgets/status_badge.dart';
import 'dashboard_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';

/// Navigation shell for R-Sync application hosting Dashboard,
/// Smart Scheduler, and Settings tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final espProvider = context.watch<EspProvider>();
    final status = espProvider.status;
    final isConnected = espProvider.isConnected;

    final screens = [
      DashboardScreen(
        onNavigateToSettings: () => setState(() => _currentIndex = 2),
      ),
      const SchedulerScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/ico.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.sync_rounded,
                  color: AppColors.teal,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.darkGray,
                ),
                children: const [
                  TextSpan(text: 'R-'),
                  TextSpan(
                    text: 'Sync',
                    style: TextStyle(color: AppColors.teal),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StatusBadge(
              isConnected: isConnected,
              ip: isConnected && status.ip.isNotEmpty
                  ? status.ip
                  : espProvider.espIp,
              wifiStatus: status.wifi,
              time: status.time,
            ),
          ),
          IconButton(
            icon: espProvider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.teal,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Status',
            onPressed: () => espProvider.refreshStatus(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm_rounded),
            label: 'Scheduler',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
