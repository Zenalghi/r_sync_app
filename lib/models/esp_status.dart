//lib/models/esp_status.dart

import 'schedule_job.dart';

/// Represents the status payload returned by the ESP32 `GET /api/status` endpoint.
class EspStatus {
  final String ip;
  final String wifi;
  final String time;
  final bool relay1;
  final bool relay2;
  final int displayPage;
  final bool activeLow;
  final List<ScheduleJob> jobs1;
  final List<ScheduleJob> jobs2;

  const EspStatus({
    required this.ip,
    required this.wifi,
    required this.time,
    required this.relay1,
    required this.relay2,
    this.displayPage = 0,
    this.activeLow = true,
    required this.jobs1,
    required this.jobs2,
  });

  /// Factory to construct empty/initial state before first fetch
  factory EspStatus.initial() {
    return const EspStatus(
      ip: '',
      wifi: 'Disconnected',
      time: 'Not Synced',
      relay1: false,
      relay2: false,
      displayPage: 0,
      activeLow: true,
      jobs1: [],
      jobs2: [],
    );
  }

  factory EspStatus.fromJson(Map<String, dynamic> json) {
    final jobs1Raw = json['jobs1'] as List<dynamic>? ?? [];
    final jobs2Raw = json['jobs2'] as List<dynamic>? ?? [];

    return EspStatus(
      ip: json['ip'] as String? ?? '',
      wifi: json['wifi'] as String? ?? 'Disconnected',
      time: json['time'] as String? ?? 'Not Synced',
      relay1: (json['relay1'] as String?)?.toUpperCase() == 'ON',
      relay2: (json['relay2'] as String?)?.toUpperCase() == 'ON',
      displayPage: json['displayPage'] as int? ?? 0,
      activeLow: json['activeLow'] as bool? ?? true,
      jobs1: jobs1Raw
          .map((item) => ScheduleJob.fromJson(item as Map<String, dynamic>))
          .toList(),
      jobs2: jobs2Raw
          .map((item) => ScheduleJob.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isWifiConnected => wifi.toLowerCase() == 'connected';

  bool get isTimeSynced =>
      time.isNotEmpty && !time.toLowerCase().contains('not synced');

  /// Gets the relay state for a specific channel (1 or 2)
  bool getRelayState(int channel) {
    return channel == 1 ? relay1 : relay2;
  }

  /// Gets the jobs list for a specific channel (1 or 2)
  List<ScheduleJob> getJobs(int channel) {
    return channel == 1 ? jobs1 : jobs2;
  }

  /// Finds the next upcoming active schedule for a given channel
  ScheduleJob? getNextActiveJob(int channel) {
    final jobs = (channel == 1 ? jobs1 : jobs2)
        .where((j) => j.enabled)
        .toList();

    if (jobs.isEmpty) return null;

    // Parse ESP32 time if available, otherwise use local DateTime
    int currentMinutes = 0;
    try {
      if (isTimeSynced) {
        final parts = time.split(' ');
        if (parts.length > 1) {
          final timeParts = parts[1].split(':');
          final h = int.parse(timeParts[0]);
          final m = int.parse(timeParts[1]);
          currentMinutes = h * 60 + m;
        }
      } else {
        final now = DateTime.now();
        currentMinutes = now.hour * 60 + now.minute;
      }
    } catch (_) {
      final now = DateTime.now();
      currentMinutes = now.hour * 60 + now.minute;
    }

    // Sort jobs chronologically
    jobs.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    // Find first job after current minute
    for (final job in jobs) {
      if (job.totalMinutes > currentMinutes) {
        return job;
      }
    }

    // Wrap around to first job tomorrow
    return jobs.first;
  }

  EspStatus copyWith({
    String? ip,
    String? wifi,
    String? time,
    bool? relay1,
    bool? relay2,
    int? displayPage,
    bool? activeLow,
    List<ScheduleJob>? jobs1,
    List<ScheduleJob>? jobs2,
  }) {
    return EspStatus(
      ip: ip ?? this.ip,
      wifi: wifi ?? this.wifi,
      time: time ?? this.time,
      relay1: relay1 ?? this.relay1,
      relay2: relay2 ?? this.relay2,
      displayPage: displayPage ?? this.displayPage,
      activeLow: activeLow ?? this.activeLow,
      jobs1: jobs1 ?? this.jobs1,
      jobs2: jobs2 ?? this.jobs2,
    );
  }
}
