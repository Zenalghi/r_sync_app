import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/schedule_job.dart';

/// Premium tactile card for controlling an ESP32 relay channel.
/// Features glowing active states, responsive micro-animations,
/// and next upcoming schedule indicators.
class RelayCard extends StatelessWidget {
  final int channel; // 1 or 2
  final String title;
  final String subtitle;
  final bool isOn;
  final bool isConnected;
  final ScheduleJob? nextJob;
  final VoidCallback onToggle;

  const RelayCard({
    super.key,
    required this.channel,
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.isConnected,
    this.nextJob,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = channel == 1 ? AppColors.teal : AppColors.orange;
    final primaryLightColor =
        channel == 1 ? AppColors.tealLight : AppColors.orangeLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isOn
            ? (isDark
                ? (channel == 1
                    ? AppColors.tealContainerDark.withValues(alpha: 0.4)
                    : AppColors.orangeContainerDark.withValues(alpha: 0.4))
                : (channel == 1
                    ? AppColors.tealContainer.withValues(alpha: 0.5)
                    : AppColors.orangeContainer.withValues(alpha: 0.5)))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOn
              ? primaryColor.withValues(alpha: 0.8)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isOn ? 2 : 1,
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: isConnected ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Channel Badge & Power Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon + Channel label
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isOn
                                ? primaryColor
                                : (isDark
                                    ? AppColors.darkSurface
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            channel == 1
                                ? Icons.bolt_rounded
                                : Icons.power_rounded,
                            color: isOn
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              subtitle,
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
                      ],
                    ),

                    // Modern Switch Button
                    Transform.scale(
                      scale: 1.05,
                      child: Switch.adaptive(
                        value: isOn,
                        onChanged: isConnected ? (_) => onToggle() : null,
                        activeThumbColor: primaryLightColor,
                        activeTrackColor: primaryColor.withValues(alpha: 0.5),
                        inactiveThumbColor: isDark
                            ? AppColors.darkTextMuted
                            : Colors.grey.shade400,
                        inactiveTrackColor: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // State description row & Next schedule
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOn
                            ? primaryColor.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOn ? primaryColor : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOn ? 'STATUS: MENYALA (ON)' : 'STATUS: MATI (OFF)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isOn
                                  ? primaryColor
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Upcoming Schedule
                    if (nextJob != null)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.8)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: AppColors.indigo,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${nextJob!.timeString} (${nextJob!.action})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
