import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/schedule_job.dart';

/// Card displaying an active schedule item with time, action badge,
/// toggle switch, and edit/delete actions.
class ScheduleCard extends StatelessWidget {
  final ScheduleJob job;
  final int index;
  final int channel; // 1 or 2
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.job,
    required this.index,
    required this.channel,
    required this.onToggleEnabled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnAction = job.isActionOn;
    final actionColor = isOnAction ? AppColors.teal : AppColors.orange;
    final actionLight = isOnAction
        ? AppColors.tealLight
        : AppColors.orangeLight;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: job.enabled ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: job.enabled
                ? actionColor.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: job.enabled ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Clock Icon + Time
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? (isOnAction
                            ? AppColors.tealContainerDark
                            : AppColors.orangeContainerDark)
                      : (isOnAction
                            ? AppColors.tealContainer
                            : AppColors.orangeContainer),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time_filled_rounded,
                  color: isOnAction ? actionColor : actionLight,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Time & Action details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          job.timeString,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WIB',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Action Pill: NYALAKAN / MATIKAN + Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOnAction ? '⚡ NYALAKAN' : '⭕ MATIKAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: actionColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            job.enabled ? 'Aktif' : 'Nonaktif',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: job.enabled
                                  ? AppColors.emerald
                                  : (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Enable/Disable switch
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: job.enabled,
                  onChanged: onToggleEnabled,
                  activeThumbColor: actionLight,
                  activeTrackColor: actionColor.withValues(alpha: 0.5),
                ),
              ),

              // Popup menu: Edit & Delete
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: isDark ? AppColors.darkSurface : Colors.white,
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit Jadwal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 10),
                        Text('Hapus', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
