import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/schedule_job.dart';

/// Modal dialog for adding or editing a schedule job.
/// Implements smart suggestions for action (alternating ON/OFF) and time.
class SmartJobDialog extends StatefulWidget {
  final int channel; // 1 or 2
  final ScheduleJob? existingJob; // null if adding new
  final String recommendedAction; // 'ON' or 'OFF'
  final TimeOfDay recommendedTime;
  final ValueChanged<ScheduleJob> onSave;

  const SmartJobDialog({
    super.key,
    required this.channel,
    this.existingJob,
    required this.recommendedAction,
    required this.recommendedTime,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required int channel,
    ScheduleJob? existingJob,
    required String recommendedAction,
    required TimeOfDay recommendedTime,
    required ValueChanged<ScheduleJob> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartJobDialog(
        channel: channel,
        existingJob: existingJob,
        recommendedAction: recommendedAction,
        recommendedTime: recommendedTime,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SmartJobDialog> createState() => _SmartJobDialogState();
}

class _SmartJobDialogState extends State<SmartJobDialog> {
  late TimeOfDay _selectedTime;
  late String _selectedAction;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    if (widget.existingJob != null) {
      _selectedTime = TimeOfDay(
        hour: widget.existingJob!.hour,
        minute: widget.existingJob!.minute,
      );
      _selectedAction = widget.existingJob!.action;
      _isEnabled = widget.existingJob!.enabled;
    } else {
      _selectedTime = widget.recommendedTime;
      _selectedAction = widget.recommendedAction;
      _isEnabled = true;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingJob != null;
    final primaryColor =
        widget.channel == 1 ? AppColors.teal : AppColors.orange;

    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title & Channel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Jadwal' : 'Tambah Jadwal Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Relay ${widget.channel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Smart Suggestion Tip (if new and recommended)
          if (!isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : AppColors.indigoContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.indigo.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Smart Suggestion: Aksi disetel otomatis ke "$_selectedAction" berdasarkan status jadwal sebelumnya.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          // Time Picker Field
          Text(
            'WAKTU JADWAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),

          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: primaryColor,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'WIB',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Ubah Jam',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action Selection (ON vs OFF)
          Text(
            'AKSI RELAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // ON Option
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _selectedAction = 'ON';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedAction == 'ON'
                          ? AppColors.teal.withValues(alpha: 0.2)
                          : (isDark
                              ? AppColors.darkCard
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedAction == 'ON'
                            ? AppColors.teal
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: _selectedAction == 'ON'
                              ? AppColors.teal
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade600),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NYALAKAN (ON)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedAction == 'ON'
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
              ),

              const SizedBox(width: 12),

              // OFF Option
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _selectedAction = 'OFF';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedAction == 'OFF'
                          ? AppColors.orange.withValues(alpha: 0.2)
                          : (isDark
                              ? AppColors.darkCard
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedAction == 'OFF'
                            ? AppColors.orange
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.power_off_rounded,
                          color: _selectedAction == 'OFF'
                              ? AppColors.orange
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade600),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MATIKAN (OFF)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedAction == 'OFF'
                                ? AppColors.orange
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Enable toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktifkan Jadwal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Switch.adaptive(
                value: _isEnabled,
                onChanged: (val) => setState(() => _isEnabled = val),
                activeThumbColor: primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Save button
          ElevatedButton(
            onPressed: () {
              final job = ScheduleJob(
                hour: _selectedTime.hour,
                minute: _selectedTime.minute,
                action: _selectedAction,
                enabled: _isEnabled,
              );
              widget.onSave(job);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isEditing ? 'Simpan Perubahan' : 'Tambahkan ke ESP32',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
