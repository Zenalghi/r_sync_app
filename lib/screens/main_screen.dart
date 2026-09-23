// lib/screens/main_screen.dart

import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';
import '../widgets/status_badge.dart';
import 'dashboard_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';
import 'timer_screen.dart';

/// Navigation shell for R-Sync application hosting Dashboard,
/// Countdown Timer, Smart Scheduler, and Settings tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isRailExtended = false;

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    try {
      return io.Platform.isWindows ||
          io.Platform.isMacOS ||
          io.Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final espProvider = context.watch<EspProvider>();
    final status = espProvider.status;
    final isConnected = espProvider.isConnected;

    final screens = [
      DashboardScreen(
        onNavigateToSettings: () => setState(() => _currentIndex = 3),
      ),
      const TimerScreen(),
      const SchedulerScreen(),
      const SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavRail = _isDesktopOrWeb && constraints.maxWidth >= 550;

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
          body: Row(
            children: [
              if (useNavRail) ...[
                NavigationRail(
                  extended: _isRailExtended,
                  backgroundColor:
                      isDark ? AppColors.darkSurface : Colors.white,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: _isRailExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  indicatorColor: AppColors.teal.withValues(alpha: 0.18),
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selectedIconTheme:
                      const IconThemeData(color: AppColors.teal, size: 24),
                  unselectedIconTheme: IconThemeData(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    size: 22,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: IconButton(
                      icon: Icon(
                        _isRailExtended
                            ? Icons.menu_open_rounded
                            : Icons.menu_rounded,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      tooltip:
                          _isRailExtended ? 'Ciutkan Menu' : 'Perluas Menu',
                      onPressed: () {
                        setState(() {
                          _isRailExtended = !_isRailExtended;
                        });
                      },
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.timer_outlined),
                      selectedIcon: Icon(Icons.timer_rounded),
                      label: Text('Timer'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.alarm_outlined),
                      selectedIcon: Icon(Icons.alarm_rounded),
                      label: Text('Scheduler'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Pengaturan'),
                    ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ],
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: useNavRail
              ? null
              : NavigationBar(
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
                      icon: Icon(Icons.timer_outlined),
                      selectedIcon: Icon(Icons.timer_rounded),
                      label: 'Timer',
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
      },
    );
  }
}
