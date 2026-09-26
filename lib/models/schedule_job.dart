// lib/models/schedule_job.dart

/// Represents a global schedule entry that can target multiple relays and switches.
/// Format v2: multi-channel (matches ESP32 v3.0.0 ScheduleEntry struct).
class ScheduleJob {
  final int hour;
  final int minute;
  final String action; // 'ON' or 'OFF'
  final bool enabled;
  final List<bool> targetRelays;   // Which relays this schedule controls
  final List<bool> targetSwitches; // Which switches this schedule controls

  const ScheduleJob({
    required this.hour,
    required this.minute,
    required this.action,
    required this.enabled,
    required this.targetRelays,
    required this.targetSwitches,
  });

  /// Formatted time string e.g. "08:05" or "14:30"
  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Minutes from midnight for sorting
  int get totalMinutes => hour * 60 + minute;

  /// Whether this job turns the device ON
  bool get isActionOn => action.toUpperCase() == 'ON';

  /// Whether this entry has no targets selected
  bool get hasNoTargets =>
      targetRelays.every((r) => !r) && targetSwitches.every((s) => !s);

  /// Human-readable target summary
  String targetSummary({int relayCount = 4, int switchCount = 3}) {
    final parts = <String>[];
    for (int i = 0; i < relayCount && i < targetRelays.length; i++) {
      if (targetRelays[i]) parts.add('R${i + 1}');
    }
    final switchNames = ['A', 'B', 'C'];
    for (int i = 0; i < switchCount && i < targetSwitches.length; i++) {
      if (targetSwitches[i]) {
        parts.add('Sw${i < switchNames.length ? switchNames[i] : (i + 1).toString()}');
      }
    }
    return parts.isEmpty ? 'Tanpa Target' : parts.join(', ');
  }

  /// Creates a blank inactive job
  factory ScheduleJob.empty({int relayCount = 4, int switchCount = 3}) {
    return ScheduleJob(
      hour: 0,
      minute: 0,
      action: 'OFF',
      enabled: false,
      targetRelays: List.filled(relayCount, false),
      targetSwitches: List.filled(switchCount, false),
    );
  }

  /// Creates a ScheduleJob from ESP32 JSON payload (v3.0.0 format)
  factory ScheduleJob.fromJson(Map<String, dynamic> json, {int relayCount = 4, int switchCount = 3}) {
    List<bool> relays = List.filled(relayCount, false);
    if (json['r'] is List) {
      final rList = json['r'] as List<dynamic>;
      for (int i = 0; i < relayCount && i < rList.length; i++) {
        relays[i] = rList[i] as bool? ?? false;
      }
    }

    List<bool> switches = List.filled(switchCount, false);
    if (json['s'] is List) {
      final sList = json['s'] as List<dynamic>;
      for (int i = 0; i < switchCount && i < sList.length; i++) {
        switches[i] = sList[i] as bool? ?? false;
      }
    }

    return ScheduleJob(
      hour: (json['h'] as num?)?.toInt() ?? 0,
      minute: (json['m'] as num?)?.toInt() ?? 0,
      action: (json['a'] as String?)?.toUpperCase() == 'ON' ? 'ON' : 'OFF',
      enabled: json['e'] as bool? ?? false,
      targetRelays: relays,
      targetSwitches: switches,
    );
  }

  /// Serializes to ESP32 JSON payload format (v3.0.0)
  Map<String, dynamic> toJson() {
    return {
      'h': hour,
      'm': minute,
      'a': action.toUpperCase() == 'ON' ? 'ON' : 'OFF',
      'e': enabled,
      'r': targetRelays,
      's': targetSwitches,
    };
  }

  ScheduleJob copyWith({
    int? hour,
    int? minute,
    String? action,
    bool? enabled,
    List<bool>? targetRelays,
    List<bool>? targetSwitches,
  }) {
    return ScheduleJob(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
      targetRelays: targetRelays ?? List<bool>.from(this.targetRelays),
      targetSwitches: targetSwitches ?? List<bool>.from(this.targetSwitches),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleJob &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute &&
          action == other.action &&
          enabled == other.enabled;

  @override
  int get hashCode =>
      hour.hashCode ^ minute.hashCode ^ action.hashCode ^ enabled.hashCode;
}
