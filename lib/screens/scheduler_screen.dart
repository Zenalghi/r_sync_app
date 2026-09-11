import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/schedule_job.dart';
import '../providers/esp_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_card.dart';
import '../widgets/smart_job_dialog.dart';

/// Smart Scheduler screen for configuring automated timers for Relay 1 and Relay 2.
/// Dynamically shows only configured schedules (no blank cards), alternates smart recommendations,
/// and limits to 4 jobs per relay according to ESP32 hardware capability.
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  int _selectedChannel = 1; // 1 or 2

  @override
  void initState() {
    super.initState();
    // Synchronize initial jobs from ESP32 status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final espStatus = context.read<EspProvider>().status;
      context.read<ScheduleProvider>().updateFromEspStatus(
            espStatus.jobs1,
            espStatus.jobs2,
          );
    });
  }

  void _openAddJobModal() {
    final scheduleProvider = context.read<ScheduleProvider>();
    final espProvider = context.read<EspProvider>();

    if (!scheduleProvider.canAddJob(_selectedChannel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Maksimal 4 jadwal per relay sudah tercapai!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final recommendedAction =
        scheduleProvider.getNextRecommendedAction(_selectedChannel);
    final recommendedTime =
        scheduleProvider.getNextRecommendedTime(_selectedChannel);

    SmartJobDialog.show(
      context: context,
      channel: _selectedChannel,
      recommendedAction: recommendedAction,
      recommendedTime: recommendedTime,
      onSave: (newJob) async {
        final success = await scheduleProvider.addJob(
          espIp: espProvider.espIp,
          channel: _selectedChannel,
          newJob: newJob,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Jadwal ${newJob.timeString} (${newJob.action}) berhasil disimpan ke ESP32!',
                ),
                backgroundColor: AppColors.emerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
            espProvider.refreshStatus();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  scheduleProvider.errorMessage ?? 'Gagal menyimpan jadwal.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  void _openEditJobModal(int index, ScheduleJob job) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final espProvider = context.read<EspProvider>();

    SmartJobDialog.show(
      context: context,
      channel: _selectedChannel,
      existingJob: job,
      recommendedAction: job.action,
      recommendedTime: TimeOfDay(hour: job.hour, minute: job.minute),
      onSave: (updatedJob) async {
        final success = await scheduleProvider.updateJob(
          espIp: espProvider.espIp,
          channel: _selectedChannel,
          index: index,
          updatedJob: updatedJob,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Jadwal diperbarui menjadi ${updatedJob.timeString} (${updatedJob.action})!',
                ),
                backgroundColor: AppColors.emerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
            espProvider.refreshStatus();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  scheduleProvider.errorMessage ?? 'Gagal memperbarui jadwal.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  void _confirmDeleteJob(int index, ScheduleJob job) {
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
          'Apakah Anda yakin ingin menghapus jadwal pukul ${job.timeString} (${job.action}) dari Relay $_selectedChannel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await scheduleProvider.deleteJob(
                espIp: espProvider.espIp,
                channel: _selectedChannel,
                index: index,
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jadwal berhasil dihapus dari ESP32.'),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  espProvider.refreshStatus();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        scheduleProvider.errorMessage ?? 'Gagal menghapus jadwal.',
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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

    // Listen to status updates from ESP32 if not saving
    if (!scheduleProvider.isSaving && espProvider.status.jobs1.isNotEmpty) {
      // Sync softly
      final esp1 = espProvider.status.jobs1;
      final esp2 = espProvider.status.jobs2;
      // Only sync if counts or values changed
      if (esp1.isNotEmpty || esp2.isNotEmpty) {
        // Safe update
      }
    }

    final currentJobs = scheduleProvider.getJobs(_selectedChannel);
    final canAdd = scheduleProvider.canAddJob(_selectedChannel);
    final primaryColor =
        _selectedChannel == 1 ? AppColors.teal : AppColors.orange;

    return Scaffold(
      body: Column(
        children: [
          // Channel Selector Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildChannelTab(
                    channel: 1,
                    title: 'Relay 1 (Teal)',
                    color: AppColors.teal,
                    count: scheduleProvider.getJobs(1).length,
                    isSelected: _selectedChannel == 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChannelTab(
                    channel: 2,
                    title: 'Relay 2 (Orange)',
                    color: AppColors.orange,
                    count: scheduleProvider.getJobs(2).length,
                    isSelected: _selectedChannel == 2,
                  ),
                ),
              ],
            ),
          ),

          // Saving overlay banner
          if (scheduleProvider.isSaving)
            LinearProgressIndicator(
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              color: primaryColor,
              minHeight: 3,
            ),

          // Slot capacity bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_send_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Jadwal Otomatis Relay $_selectedChannel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: currentJobs.length >= 4
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentJobs.length} / 4 Slot',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: currentJobs.length >= 4
                          ? AppColors.warning
                          : primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Schedule List or Empty State
          Expanded(
            child: currentJobs.isEmpty
                ? _buildEmptyState(isDark, primaryColor)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                    itemCount: currentJobs.length,
                    itemBuilder: (ctx, index) {
                      final job = currentJobs[index];
                      return ScheduleCard(
                        job: job,
                        index: index,
                        channel: _selectedChannel,
                        onToggleEnabled: (val) {
                          scheduleProvider.toggleJobEnabled(
                            espIp: espProvider.espIp,
                            channel: _selectedChannel,
                            index: index,
                          );
                        },
                        onEdit: () => _openEditJobModal(index, job),
                        onDelete: () => _confirmDeleteJob(index, job),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Floating Add Schedule Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canAdd ? _openAddJobModal : null,
        backgroundColor: canAdd
            ? primaryColor
            : (isDark ? AppColors.darkCard : Colors.grey.shade300),
        foregroundColor: canAdd ? Colors.white : Colors.grey.shade500,
        elevation: canAdd ? 4 : 0,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          canAdd ? 'Tambah Jadwal' : 'Slot Penuh (4/4)',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildChannelTab({
    required int channel,
    required String title,
    required Color color,
    required int count,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedChannel = channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Relay $channel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
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
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm_add_rounded,
                size: 40,
                color: primaryColor,
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
              'Buat timer otomatis untuk Relay $_selectedChannel. Sistem akan menyarankan aksi ON/OFF secara otomatis.',
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
              onPressed: _openAddJobModal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Jadwal Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
