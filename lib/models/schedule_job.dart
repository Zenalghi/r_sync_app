/// Represents a scheduled timer job for an ESP32 relay channel.
/// Corresponds to the Job struct in the ESP32 firmware.
class ScheduleJob {
  final int hour;
  final int minute;
  final String action; // 'ON' or 'OFF'
  final bool enabled;

  const ScheduleJob({
    required this.hour,
    required this.minute,
    required this.action,
    required this.enabled,
  });

  /// Formatted time string e.g. "08:05" or "14:30"
  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Minutes from midnight for sorting and comparison
  int get totalMinutes => hour * 60 + minute;

  /// Whether this job turns the relay ON
  bool get isActionOn => action.toUpperCase() == 'ON';

  /// Whether this job represents an unconfigured or empty slot
  bool get isEmptySlot => !enabled && hour == 0 && minute == 0;

  /// Creates a blank inactive job slot
  factory ScheduleJob.empty() {
    return const ScheduleJob(
      hour: 0,
      minute: 0,
      action: 'OFF',
      enabled: false,
    );
  }

  /// Creates a ScheduleJob from ESP32 JSON payload
  factory ScheduleJob.fromJson(Map<String, dynamic> json) {
    return ScheduleJob(
      hour: (json['h'] as num?)?.toInt() ?? 0,
      minute: (json['m'] as num?)?.toInt() ?? 0,
      action: (json['a'] as String?)?.toUpperCase() == 'ON' ? 'ON' : 'OFF',
      enabled: json['e'] as bool? ?? false,
    );
  }

  /// Serializes to ESP32 JSON payload format
  Map<String, dynamic> toJson() {
    return {
      'h': hour,
      'm': minute,
      'a': action.toUpperCase() == 'ON' ? 'ON' : 'OFF',
      'e': enabled,
    };
  }

  ScheduleJob copyWith({
    int? hour,
    int? minute,
    String? action,
    bool? enabled,
  }) {
    return ScheduleJob(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
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
