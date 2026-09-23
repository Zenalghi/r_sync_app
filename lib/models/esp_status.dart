// lib/models/esp_status.dart

import 'schedule_job.dart';
import 'timer_job.dart';

/// Represents the status payload returned by the ESP32 `GET /api/status` endpoint.
class EspStatus {
  final String ip;
  final String wifi;
  final String time;
  final List<bool> relays; // Relays 1..N
  final List<bool> switches; // Wall Switches A..N
  final int displayPage;
  final bool activeLow;
  final int restAngle;
  final int pressAngle;
  final int pressDurationMs;
  final List<TimerJob> timers;
  final List<ScheduleJob> jobs1; // Backward compatibility
  final List<ScheduleJob> jobs2; // Backward compatibility

  const EspStatus({
    required this.ip,
    required this.wifi,
    required this.time,
    required this.relays,
    required this.switches,
    this.displayPage = 0,
    this.activeLow = true,
    this.restAngle = 90,
    this.pressAngle = 0,
    this.pressDurationMs = 400,
    required this.timers,
    required this.jobs1,
    required this.jobs2,
  });

  factory EspStatus.initial() {
    return const EspStatus(
      ip: '',
      wifi: 'Disconnected',
      time: 'Not Synced',
      relays: [false, false, false, false],
      switches: [false, false, false],
      displayPage: 0,
      activeLow: true,
      restAngle: 90,
      pressAngle: 0,
      pressDurationMs: 400,
      timers: [],
      jobs1: [],
      jobs2: [],
    );
  }

  factory EspStatus.fromJson(Map<String, dynamic> json) {
    List<bool> relayList = [];
    if (json['relays'] is List) {
      relayList = (json['relays'] as List<dynamic>)
          .map((e) => (e.toString().toUpperCase() == 'ON'))
          .toList();
    } else {
      bool r1 = (json['relay1'] as String?)?.toUpperCase() == 'ON';
      bool r2 = (json['relay2'] as String?)?.toUpperCase() == 'ON';
      relayList = [r1, r2];
    }

    List<bool> switchList = [];
    if (json['switches'] is List) {
      switchList = (json['switches'] as List<dynamic>)
          .map((e) => (e.toString().toUpperCase() == 'ON'))
          .toList();
    } else {
      switchList = [false, false, false];
    }

    List<TimerJob> timerList = [];
    if (json['timers'] is List) {
      timerList = (json['timers'] as List<dynamic>)
          .map((item) => TimerJob.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final jobs1Raw = json['jobs1'] as List<dynamic>? ?? [];
    final jobs2Raw = json['jobs2'] as List<dynamic>? ?? [];

    return EspStatus(
      ip: json['ip'] as String? ?? '',
      wifi: json['wifi'] as String? ?? 'Disconnected',
      time: json['time'] as String? ?? 'Not Synced',
      relays: relayList,
      switches: switchList,
      displayPage: json['displayPage'] as int? ?? 0,
      activeLow: json['activeLow'] as bool? ?? true,
      restAngle: json['restAngle'] as int? ?? 90,
      pressAngle: json['pressAngle'] as int? ?? 0,
      pressDurationMs: json['pressDurationMs'] as int? ?? 400,
      timers: timerList,
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

  bool getRelayState(int channel) {
    if (channel < 1 || channel > relays.length) return false;
    return relays[channel - 1];
  }

  bool getSwitchState(int switchIdx) {
    if (switchIdx < 0 || switchIdx >= switches.length) return false;
    return switches[switchIdx];
  }

  bool get relay1 => getRelayState(1);
  bool get relay2 => getRelayState(2);
  bool get relay3 => getRelayState(3);
  bool get relay4 => getRelayState(4);

  ScheduleJob? getNextActiveJob(int channel) {
    final jobs = (channel == 1 ? jobs1 : jobs2).where((j) => j.enabled).toList();
    if (jobs.isEmpty) return null;
    return jobs.first;
  }

  EspStatus copyWith({
    String? ip,
    String? wifi,
    String? time,
    List<bool>? relays,
    List<bool>? switches,
    int? displayPage,
    bool? activeLow,
    int? restAngle,
    int? pressAngle,
    int? pressDurationMs,
    List<TimerJob>? timers,
    List<ScheduleJob>? jobs1,
    List<ScheduleJob>? jobs2,
  }) {
    return EspStatus(
      ip: ip ?? this.ip,
      wifi: wifi ?? this.wifi,
      time: time ?? this.time,
      relays: relays ?? this.relays,
      switches: switches ?? this.switches,
      displayPage: displayPage ?? this.displayPage,
      activeLow: activeLow ?? this.activeLow,
      restAngle: restAngle ?? this.restAngle,
      pressAngle: pressAngle ?? this.pressAngle,
      pressDurationMs: pressDurationMs ?? this.pressDurationMs,
      timers: timers ?? this.timers,
      jobs1: jobs1 ?? this.jobs1,
      jobs2: jobs2 ?? this.jobs2,
    );
  }
}
