// lib/screens/scheduler_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/schedule_job.dart';
import '../providers/esp_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_card.dart';
import '../widgets/smart_job_dialog.dart';

/// Smart Scheduler screen for configuring automated timers for Relays (1..4) and Servo Switches (A..C).
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  int _selectedChannelIndex = 0; // 0..3 for Relays 1..4, 4..6 for Switches A..C

  String _getChannelName(int index) {
    if (index < 4) {
      return 'Relay ${index + 1}';
    } else {
      final names = ['A', 'B', 'C'];
      final idx = index - 4;
      final name = idx < names.length ? names[idx] : '${idx + 1}';
      return 'Switch $name';
    }
  }

  void _openAddJobModal() {
    final scheduleProvider = context.read<ScheduleProvider>();
    final espProvider = context.read<EspProvider>();

    // Map _selectedChannelIndex + 1 for legacy ScheduleProvider channel indexing (1-based for relays, 5-based for switches)
    final ch = _selectedChannelIndex + 1;

    if (!scheduleProvider.canAddJob(ch)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maksimal 4 jadwal per channel sudah tercapai!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final recommendedAction = scheduleProvider.getNextRecommendedAction(ch);
    final recommendedTime = scheduleProvider.getNextRecommendedTime(ch);

    SmartJobDialog.show(
      context: context,
      channel: ch,
      recommendedAction: recommendedAction,
      recommendedTime: recommendedTime,
      onSave: (newJob) async {
        final success = await scheduleProvider.addJob(
          espIp: espProvider.espIp,
          channel: _selectedChannelIndex, // ESP32 uses 0-based channel index
          newJob: newJob,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Jadwal ${newJob.timeString} (${newJob.action}) berhasil disimpan!',
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
    final ch = _selectedChannelIndex + 1;

    SmartJobDialog.show(
      context: context,
      channel: ch,
      existingJob: job,
      recommendedAction: job.action,
      recommendedTime: TimeOfDay(hour: job.hour, minute: job.minute),
      onSave: (updatedJob) async {
        final success = await scheduleProvider.updateJob(
          espIp: espProvider.espIp,
          channel: _selectedChannelIndex,
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
          'Apakah Anda yakin ingin menghapus jadwal pukul ${job.timeString} (${job.action}) dari ${_getChannelName(_selectedChannelIndex)}?',
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
                channel: _selectedChannelIndex,
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
    final caps = espProvider.capabilities;

    final totalChannels = caps.relaysCount + caps.switchesCount;
    final ch = _selectedChannelIndex + 1;
    final currentJobs = scheduleProvider.getJobs(ch);
    final canAdd = scheduleProvider.canAddJob(ch);
    final primaryColor = AppColors.teal;

    return Scaffold(
      body: Column(
        children: [
          // Channel Selector Tabs Scrollable
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalChannels,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedChannelIndex == index;
                final channelName = _getChannelName(index);
                final jobCount = scheduleProvider.getJobs(index + 1).length;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedChannelIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.teal.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkCard : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.teal : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          channelName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.teal : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.teal : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$jobCount',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (scheduleProvider.isSaving)
            const LinearProgressIndicator(
              backgroundColor: AppColors.tealLight,
              color: AppColors.teal,
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
                    const Icon(
                      Icons.schedule_send_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Jadwal Otomatis ${_getChannelName(_selectedChannelIndex)}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        channel: ch,
                        onToggleEnabled: (val) {
                          scheduleProvider.toggleJobEnabled(
                            espIp: espProvider.espIp,
                            channel: _selectedChannelIndex,
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
              'Buat timer otomatis untuk ${_getChannelName(_selectedChannelIndex)}. Sistem akan menyarankan aksi ON/OFF secara otomatis.',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
