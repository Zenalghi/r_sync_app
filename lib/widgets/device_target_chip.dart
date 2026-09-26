// lib/widgets/device_target_chip.dart

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Consistently styled selection chip for picking target devices
/// (Relay 1-4 / Switch A-C) in the Timer and Scheduler dialogs.
class DeviceTargetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final ValueChanged<bool> onSelected;

  const DeviceTargetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accent = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? accent
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: onSelected,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      selectedColor: accent,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected
            ? Colors.white
            : (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
      ),
      side: BorderSide(color: borderColor, width: selected ? 1.4 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
  }
}
