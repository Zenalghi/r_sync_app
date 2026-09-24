// lib/screens/timer_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/timer_job.dart';
import '../providers/esp_provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  void _showAddTimerDialog(BuildContext context) {
    final espProvider = context.read<EspProvider>();
    final caps = espProvider.capabilities;

    int hours = 0;
    int minutes = 5;
    int seconds = 0;
    String targetAction = 'ON';
    bool invertOnStartEnd = true;

    final List<bool> selectedRelays = List.filled(caps.relaysCount, false);
    final List<bool> selectedSwitches = List.filled(caps.switchesCount, false);
    if (selectedRelays.isNotEmpty) selectedRelays[0] = true;

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
                    Row(
                      children: [
                        const Icon(Icons.timer_rounded, color: AppColors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah Timer Baru',
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
                    const SizedBox(height: 16),

                    Text(
                      'DURASI WAKTU (JAM : MENIT : DETIK)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.tealLight : AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: hours,
                            decoration: const InputDecoration(labelText: 'Jam'),
                            items: List.generate(
                              24,
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text('$i Jam'),
                              ),
                            ),
                            onChanged: (val) =>
                                setModalState(() => hours = val ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: minutes,
                            decoration: const InputDecoration(
                              labelText: 'Menit',
                            ),
                            items: List.generate(
                              60,
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text('$i Mnt'),
                              ),
                            ),
                            onChanged: (val) =>
                                setModalState(() => minutes = val ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: seconds,
                            decoration: const InputDecoration(
                              labelText: 'Detik',
                            ),
                            items: List.generate(
                              60,
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text('$i Dtk'),
                              ),
                            ),
                            onChanged: (val) =>
                                setModalState(() => seconds = val ?? 0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'AKSI TARGET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.tealLight : AppColors.teal,
                      ),
                    ),
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
                      selected: {targetAction},
                      onSelectionChanged: (val) =>
                          setModalState(() => targetAction = val.first),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'PILIH PERANGKAT TERKAIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.tealLight : AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (caps.relaysCount > 0)
                      Wrap(
                        spacing: 8,
                        children: List.generate(caps.relaysCount, (index) {
                          return FilterChip(
                            label: Text('Relay ${index + 1}'),
                            selected: selectedRelays[index],
                            onSelected: (val) {
                              setModalState(() => selectedRelays[index] = val);
                            },
                          );
                        }),
                      ),

                    if (caps.switchesCount > 0)
                      Wrap(
                        spacing: 8,
                        children: List.generate(caps.switchesCount, (index) {
                          final names = ['A', 'B', 'C'];
                          final name = index < names.length
                              ? names[index]
                              : '${index + 1}';
                          return FilterChip(
                            label: Text('Switch $name'),
                            selected: selectedSwitches[index],
                            onSelected: (val) {
                              setModalState(
                                () => selectedSwitches[index] = val,
                              );
                            },
                          );
                        }),
                      ),

                    const SizedBox(height: 16),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: invertOnStartEnd,
                      title: const Text(
                        'Lakukan kebalikan saat mulai',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(
                        'Trigger kebalikan saat timer dimulai, lalu kembalikan saat timer habis.',
                        style: TextStyle(fontSize: 11),
                      ),
                      onChanged: (val) =>
                          setModalState(() => invertOnStartEnd = val ?? false),
                    ),

                    const SizedBox(height: 20),

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
                            onPressed: () async {
                              final totalSec =
                                  (hours * 3600) + (minutes * 60) + seconds;
                              if (totalSec <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Durasi timer harus lebih dari 0 detik',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              final ok = await espProvider.addTimer(
                                durationSec: totalSec,
                                invertOnStartEnd: invertOnStartEnd,
                                targetAction: targetAction,
                                targetRelays: selectedRelays,
                                targetSwitches: selectedSwitches,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Timer berhasil dibuat'
                                          : 'Gagal membuat timer',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Mulai Timer'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final espProvider = context.watch<EspProvider>();
    final timers = espProvider.status.timers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timer Pewaktu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: timers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_off_rounded,
                    size: 64,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Timer Aktif',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tekan tombol + di bawah untuk membuat timer baru',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: timers.length,
              itemBuilder: (context, index) {
                final timer = timers[index];
                return _buildTimerCard(context, espProvider, timer);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTimerDialog(context),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Timer Baru'),
      ),
    );
  }

  Widget _buildTimerCard(
    BuildContext context,
    EspProvider espProvider,
    TimerJob timer,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    timer.paused
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color: timer.paused ? AppColors.orange : AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Timer #${timer.id}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (timer.targetAction == 'ON'
                              ? AppColors.teal
                              : AppColors.orange)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Trigger: ${timer.targetAction}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: timer.targetAction == 'ON'
                        ? AppColors.teal
                        : AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            timer.formattedRemaining,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: timer.progress,
            backgroundColor: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            color: timer.paused ? AppColors.orange : AppColors.teal,
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (timer.paused)
                TextButton.icon(
                  onPressed: () => espProvider.controlTimer(timer.id, 'resume'),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Lanjutkan'),
                )
              else
                TextButton.icon(
                  onPressed: () => espProvider.controlTimer(timer.id, 'pause'),
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: const Text('Jeda'),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => espProvider.controlTimer(timer.id, 'cancel'),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Batalkan',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
