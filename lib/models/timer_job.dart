// lib/models/timer_job.dart

/// Represents an active countdown timer from the ESP32 server.
class TimerJob {
  final int id;
  final int totalDurationSec;
  final int remainingSec;
  final bool paused;
  final bool invertOnStartEnd;
  final String targetAction; // "ON" or "OFF"
  final List<bool> targetRelays;
  final List<bool> targetSwitches;

  const TimerJob({
    required this.id,
    required this.totalDurationSec,
    required this.remainingSec,
    required this.paused,
    required this.invertOnStartEnd,
    required this.targetAction,
    required this.targetRelays,
    required this.targetSwitches,
  });

  factory TimerJob.fromJson(Map<String, dynamic> json) {
    final rList = (json['targetRelays'] as List<dynamic>?)
            ?.map((e) => e as bool)
            .toList() ??
        [];
    final sList = (json['targetSwitches'] as List<dynamic>?)
            ?.map((e) => e as bool)
            .toList() ??
        [];

    return TimerJob(
      id: json['id'] as int? ?? 0,
      totalDurationSec: json['totalDurationSec'] as int? ?? 0,
      remainingSec: json['remainingSec'] as int? ?? 0,
      paused: json['paused'] as bool? ?? false,
      invertOnStartEnd: json['invertOnStartEnd'] as bool? ?? false,
      targetAction: json['targetAction'] as String? ?? 'ON',
      targetRelays: rList,
      targetSwitches: sList,
    );
  }

  String get formattedRemaining {
    final h = (remainingSec ~/ 3600).toString().padLeft(2, '0');
    final m = ((remainingSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedTotal {
    final h = (totalDurationSec ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalDurationSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalDurationSec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double get progress {
    if (totalDurationSec == 0) return 0.0;
    return (totalDurationSec - remainingSec) / totalDurationSec;
  }
}
