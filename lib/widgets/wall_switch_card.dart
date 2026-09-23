// lib/widgets/wall_switch_card.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WallSwitchCard extends StatelessWidget {
  final int switchIdx;
  final String title;
  final String subtitle;
  final bool isOn;
  final bool isConnected;
  final VoidCallback onToggle;

  const WallSwitchCard({
    super.key,
    required this.switchIdx,
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.isConnected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isOn ? AppColors.teal : inactiveColor)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: isOn ? AppColors.teal : inactiveColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          Switch(
            value: isOn,
            onChanged: isConnected ? (_) => onToggle() : null,
            activeThumbColor: AppColors.teal,
          ),
        ],
      ),
    );
  }
}
