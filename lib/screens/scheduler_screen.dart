// lib/screens/scheduler_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/schedule_job.dart';
import '../providers/esp_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/device_target_chip.dart';

/// Smart Scheduler screen — global multi-channel schedule entries (max 10).
/// Each entry selects a time, action (ON/OFF), and any combination of relay/switch targets.
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  void _showScheduleDialog({ScheduleJob? existing, int? editIndex}) {
    final espProvider = context.read<EspProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    final caps = espProvider.capabilities;

    if (existing == null && !scheduleProvider.canAdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maksimal ${ScheduleProvider.maxSchedules} jadwal sudah tercapai!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Default values
    int hour = existing?.hour ?? TimeOfDay.now().hour;
    int minute = existing?.minute ?? TimeOfDay.now().minute;
    String action =
        existing?.action ?? scheduleProvider.getNextRecommendedAction();
    bool enabled = existing?.enabled ?? true;
    List<bool> selectedRelays = existing?.targetRelays != null
        ? List<bool>.from(existing!.targetRelays)
        : List.filled(caps.activeRelays.length, false);
    List<bool> selectedSwitches = existing?.targetSwitches != null
        ? List<bool>.from(existing!.targetSwitches)
        : List.filled(caps.activeSwitches.length, false);

    // If new, pre-select first active relay
    if (existing == null) {
      for (int i = 0; i < caps.activeRelays.length; i++) {
        if (caps.activeRelays[i]) {
          selectedRelays[i] = true;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        const Icon(
                          Icons.alarm_add_rounded,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          editIndex != null
                              ? 'Edit Jadwal'
                              : 'Tambah Jadwal Baru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Time Picker Row
                    _buildSectionLabel('WAKTU EKSEKUSI', isDark),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: hour, minute: minute),
                          builder: (context, child) => MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            hour = picked.hour;
                            minute = picked.minute;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppColors.teal,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Ketuk untuk ubah',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action ON/OFF
                    _buildSectionLabel('AKSI TARGET', isDark),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'ON',
                          label: Text('Nyalakan (ON)'),
                          icon: Icon(Icons.flash_on),
                        ),
                        ButtonSegment(
                          value: 'OFF',
                          label: Text('Matikan (OFF)'),
                          icon: Icon(Icons.flash_off),
                        ),
                      ],
                      selected: {action},
                      onSelectionChanged: (val) =>
                          setModalState(() => action = val.first),
                    ),

                    const SizedBox(height: 20),

                    // Target Devices
                    _buildSectionLabel('PILIH PERANGKAT TERKAIT', isDark),
                    const SizedBox(height: 8),

                    if (caps.hasAnyRelay) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Channel Relay',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(caps.activeRelays.length, (i) {
                          final isActive = caps.activeRelays[i];
                          if (!isActive) return const SizedBox.shrink();
                          return DeviceTargetChip(
                            label: 'Relay ${i + 1}',
                            selected:
                                i < selectedRelays.length && selectedRelays[i],
                            onSelected: (val) {
                              setModalState(() {
                                if (i < selectedRelays.length) {
                                  selectedRelays[i] = val;
                                }
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (caps.hasAnySwitch) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: AppColors.indigo,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Saklar Tembok (Servo)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(caps.activeSwitches.length, (
                          i,
                        ) {
                          final isActive = caps.activeSwitches[i];
                          if (!isActive) return const SizedBox.shrink();
                          final names = ['A', 'B', 'C'];
                          final name = i < names.length ? names[i] : '${i + 1}';
                          return DeviceTargetChip(
                            label: 'Switch $name',
                            selected:
                                i < selectedSwitches.length &&
                                selectedSwitches[i],
                            accent: AppColors.indigo,
                            onSelected: (val) {
                              setModalState(() {
                                if (i < selectedSwitches.length) {
                                  selectedSwitches[i] = val;
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],

                    // No target warning
                    if (selectedRelays.every((r) => !r) &&
                        selectedSwitches.every((s) => !s))
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Pilih minimal satu perangkat',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Enable toggle
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      onChanged: (val) => setModalState(() => enabled = val),
                      activeThumbColor: AppColors.teal,
                      title: Text(
                        'Aktifkan jadwal ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Nonaktifkan untuk simpan tanpa mengaktifkan.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save / Cancel buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (selectedRelays.any((r) => r) ||
                                    selectedSwitches.any((s) => s))
                                ? () async {
                                    Navigator.pop(ctx);
                                    final job = ScheduleJob(
                                      hour: hour,
                                      minute: minute,
                                      action: action,
                                      enabled: enabled,
                                      targetRelays: List<bool>.from(
                                        selectedRelays,
                                      ),
                                      targetSwitches: List<bool>.from(
                                        selectedSwitches,
                                      ),
                                    );
                                    bool success;
                                    if (editIndex != null) {
                                      success = await scheduleProvider
                                          .updateSchedule(
                                            espIp: espProvider.espIp,
                                            index: editIndex,
                                            updatedJob: job,
                                          );
                                    } else {
                                      success = await scheduleProvider
                                          .addSchedule(
                                            espIp: espProvider.espIp,
                                            newJob: job,
                                          );
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? editIndex != null
                                                      ? 'Jadwal berhasil diperbarui!'
                                                      : 'Jadwal ${job.timeString} berhasil ditambahkan!'
                                                : scheduleProvider
                                                          .errorMessage ??
                                                      'Gagal menyimpan jadwal.',
                                          ),
                                          backgroundColor: success
                                              ? AppColors.emerald
                                              : AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: Text(
                              editIndex != null
                                  ? 'Simpan Perubahan'
                                  : 'Tambah Jadwal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark ? AppColors.tealLight : AppColors.teal,
      ),
    );
  }

  void _confirmDelete(int index, ScheduleJob job) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final espProvider = context.read<EspProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Jadwal?'),
        content: Text(
          'Hapus jadwal pukul ${job.timeString} (${job.action}) '
          'untuk ${job.targetSummary()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await scheduleProvider.deleteSchedule(
                espIp: espProvider.espIp,
                index: index,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Jadwal berhasil dihapus.'
                          : scheduleProvider.errorMessage ??
                                'Gagal menghapus jadwal.',
                    ),
                    backgroundColor: success ? AppColors.teal : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduleProvider = context.watch<ScheduleProvider>();
    final espProvider = context.watch<EspProvider>();
    final schedules = scheduleProvider.schedules;
    final canAdd = scheduleProvider.canAdd;

    return Scaffold(
      body: Column(
        children: [
          // Capacity bar
          if (scheduleProvider.isSaving)
            const LinearProgressIndicator(
              backgroundColor: AppColors.tealLight,
              color: AppColors.teal,
              minHeight: 3,
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_send_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Jadwal Otomatis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: schedules.length >= ScheduleProvider.maxSchedules
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${schedules.length} / ${ScheduleProvider.maxSchedules} Slot',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: schedules.length >= ScheduleProvider.maxSchedules
                          ? AppColors.warning
                          : AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Schedule list
          Expanded(
            child: schedules.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                    itemCount: schedules.length,
                    itemBuilder: (ctx, index) {
                      return _buildScheduleCard(
                        context,
                        isDark,
                        espProvider,
                        scheduleProvider,
                        index,
                        schedules[index],
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: canAdd ? () => _showScheduleDialog() : null,
        backgroundColor: canAdd
            ? AppColors.teal
            : (isDark ? AppColors.darkCard : Colors.grey.shade300),
        foregroundColor: canAdd ? Colors.white : Colors.grey.shade500,
        elevation: canAdd ? 4 : 0,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          canAdd
              ? 'Tambah Jadwal'
              : 'Slot Penuh (${ScheduleProvider.maxSchedules}/${ScheduleProvider.maxSchedules})',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    bool isDark,
    EspProvider espProvider,
    ScheduleProvider scheduleProvider,
    int index,
    ScheduleJob job,
  ) {
    final isOn = job.isActionOn;
    final actionColor = isOn ? AppColors.teal : AppColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: job.enabled
              ? actionColor.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: job.enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header row: time + action badge + toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                // Time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.timeString,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: actionColor,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Action badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        size: 14,
                        color: actionColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.action,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: actionColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Enable toggle
                Switch.adaptive(
                  value: job.enabled,
                  activeThumbColor: AppColors.teal,
                  onChanged: (_) => scheduleProvider.toggleScheduleEnabled(
                    espIp: espProvider.espIp,
                    index: index,
                  ),
                ),
              ],
            ),
          ),

          // Target summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.devices_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.targetSummary(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _showScheduleDialog(existing: job, editIndex: index),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(index, job),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_add_rounded,
                size: 40,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Jadwal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat jadwal otomatis untuk relay dan switch. Setiap jadwal bisa mengontrol beberapa perangkat sekaligus.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showScheduleDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Jadwal Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
