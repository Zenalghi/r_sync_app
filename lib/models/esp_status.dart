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
  final List<bool> relayActive; // Which relay slots are active/enabled
  final List<bool> switchActive; // Which switch slots are active/enabled
  final int displayPage;
  final bool activeLow;
  final bool oledConnected; // New: OLED status from ESP
  final int restAngle;
  final int pressAngle;
  final int pressDurationMs;
  final List<TimerJob> timers;
  final List<ScheduleJob> schedules; // New: global schedule list

  const EspStatus({
    required this.ip,
    required this.wifi,
    required this.time,
    required this.relays,
    required this.switches,
    required this.relayActive,
    required this.switchActive,
    this.displayPage = 0,
    this.activeLow = true,
    this.oledConnected = false,
    this.restAngle = 90,
    this.pressAngle = 0,
    this.pressDurationMs = 400,
    required this.timers,
    required this.schedules,
  });

  factory EspStatus.initial() {
    return const EspStatus(
      ip: '',
      wifi: 'Disconnected',
      time: 'Not Synced',
      relays: [false, false, false, false],
      switches: [false, false, false],
      relayActive: [true, true, true, true],
      switchActive: [true, true, true],
      displayPage: 0,
      activeLow: true,
      oledConnected: false,
      restAngle: 90,
      pressAngle: 0,
      pressDurationMs: 400,
      timers: [],
      schedules: [],
    );
  }

  factory EspStatus.fromJson(Map<String, dynamic> json) {
    // Parse relay states
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

    // Parse switch states
    List<bool> switchList = [];
    if (json['switches'] is List) {
      switchList = (json['switches'] as List<dynamic>)
          .map((e) => (e.toString().toUpperCase() == 'ON'))
          .toList();
    } else {
      switchList = [false, false, false];
    }

    // Parse relay active flags
    List<bool> relayActiveList = List.filled(relayList.length, true);
    if (json['relayActive'] is List) {
      relayActiveList = (json['relayActive'] as List<dynamic>)
          .map((e) => e as bool? ?? true)
          .toList();
    }

    // Parse switch active flags
    List<bool> switchActiveList = List.filled(switchList.length, true);
    if (json['switchActive'] is List) {
      switchActiveList = (json['switchActive'] as List<dynamic>)
          .map((e) => e as bool? ?? true)
          .toList();
    }

    // Parse timers
    List<TimerJob> timerList = [];
    if (json['timers'] is List) {
      timerList = (json['timers'] as List<dynamic>)
          .map((item) => TimerJob.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Parse schedules (new global format)
    List<ScheduleJob> scheduleList = [];
    if (json['schedules'] is List) {
      scheduleList = (json['schedules'] as List<dynamic>)
          .map(
            (item) => ScheduleJob.fromJson(
              item as Map<String, dynamic>,
              relayCount: relayList.length,
              switchCount: switchList.length,
            ),
          )
          .where((j) => j.enabled || j.hour != 0 || j.minute != 0)
          .toList();
    }

    return EspStatus(
      ip: json['ip'] as String? ?? '',
      wifi: json['wifi'] as String? ?? 'Disconnected',
      time: json['time'] as String? ?? 'Not Synced',
      relays: relayList,
      switches: switchList,
      relayActive: relayActiveList,
      switchActive: switchActiveList,
      displayPage: json['displayPage'] as int? ?? 0,
      activeLow: json['activeLow'] as bool? ?? true,
      oledConnected: json['oledConnected'] as bool? ?? false,
      restAngle: json['restAngle'] as int? ?? 90,
      pressAngle: json['pressAngle'] as int? ?? 0,
      pressDurationMs: json['pressDurationMs'] as int? ?? 400,
      timers: timerList,
      schedules: scheduleList,
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

  bool isRelayActive(int index) {
    if (index < 0 || index >= relayActive.length) return true;
    return relayActive[index];
  }

  bool isSwitchActive(int index) {
    if (index < 0 || index >= switchActive.length) return true;
    return switchActive[index];
  }

  /// Returns the earliest enabled schedule targeting the given relay channel (1-based), if any.
  ScheduleJob? getNextActiveJobForRelay(int channel) {
    final idx = channel - 1;
    final candidates =
        schedules
            .where(
              (j) =>
                  j.enabled &&
                  idx >= 0 &&
                  idx < j.targetRelays.length &&
                  j.targetRelays[idx],
            )
            .toList()
          ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    return candidates.isEmpty ? null : candidates.first;
  }

  EspStatus copyWith({
    String? ip,
    String? wifi,
    String? time,
    List<bool>? relays,
    List<bool>? switches,
    List<bool>? relayActive,
    List<bool>? switchActive,
    int? displayPage,
    bool? activeLow,
    bool? oledConnected,
    int? restAngle,
    int? pressAngle,
    int? pressDurationMs,
    List<TimerJob>? timers,
    List<ScheduleJob>? schedules,
  }) {
    return EspStatus(
      ip: ip ?? this.ip,
      wifi: wifi ?? this.wifi,
      time: time ?? this.time,
      relays: relays ?? this.relays,
      switches: switches ?? this.switches,
      relayActive: relayActive ?? this.relayActive,
      switchActive: switchActive ?? this.switchActive,
      displayPage: displayPage ?? this.displayPage,
      activeLow: activeLow ?? this.activeLow,
      oledConnected: oledConnected ?? this.oledConnected,
      restAngle: restAngle ?? this.restAngle,
      pressAngle: pressAngle ?? this.pressAngle,
      pressDurationMs: pressDurationMs ?? this.pressDurationMs,
      timers: timers ?? this.timers,
      schedules: schedules ?? this.schedules,
    );
  }
}
