// lib/models/esp_capabilities.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents hardware and software capabilities discovered from ESP32 (`GET /api/capabilities`).
class EspCapabilities {
  final String deviceName;
  final String version;
  final int relaysCount;       // Number of ACTIVE relays
  final int switchesCount;     // Number of ACTIVE switches
  final int servosCount;
  final bool timerFeature;
  final int maxTimers;
  final bool schedulerFeature;
  final int maxSchedules;      // New: global max schedules (was maxSchedulesPerChannel)
  final bool servoConfigFeature;
  final bool oledConnected;    // New: OLED hardware detected
  final List<bool> activeRelays;   // New: which relay slots are active
  final List<bool> activeSwitches; // New: which switch slots are active

  const EspCapabilities({
    this.deviceName = 'R-Sync ESP32 Server',
    this.version = '3.0.0',
    this.relaysCount = 4,
    this.switchesCount = 3,
    this.servosCount = 6,
    this.timerFeature = true,
    this.maxTimers = 10,
    this.schedulerFeature = true,
    this.maxSchedules = 10,
    this.servoConfigFeature = true,
    this.oledConnected = false,
    this.activeRelays = const [true, true, true, true],
    this.activeSwitches = const [true, true, true],
  });

  factory EspCapabilities.initial() {
    return const EspCapabilities();
  }

  factory EspCapabilities.fromJson(Map<String, dynamic> json) {
    // Parse active relay flags
    List<bool> activeRelayList = [true, true, true, true];
    if (json['active_relays'] is List) {
      activeRelayList = (json['active_relays'] as List<dynamic>)
          .map((e) => e as bool? ?? true)
          .toList();
    }

    // Parse active switch flags
    List<bool> activeSwitchList = [true, true, true];
    if (json['active_switches'] is List) {
      activeSwitchList = (json['active_switches'] as List<dynamic>)
          .map((e) => e as bool? ?? true)
          .toList();
    }

    // Support old field name 'max_schedules_per_channel' for backward compat
    final maxSched = json['max_schedules'] as int? ??
        json['max_schedules_per_channel'] as int? ?? 10;

    return EspCapabilities(
      deviceName: json['device_name'] as String? ?? 'R-Sync ESP32 Server',
      version: json['version'] as String? ?? '3.0.0',
      relaysCount: json['relays_count'] as int? ?? 4,
      switchesCount: json['switches_count'] as int? ?? 3,
      servosCount: json['servos_count'] as int? ?? 6,
      timerFeature: json['timer_feature'] as bool? ?? true,
      maxTimers: json['max_timers'] as int? ?? 10,
      schedulerFeature: json['scheduler_feature'] as bool? ?? true,
      maxSchedules: maxSched,
      servoConfigFeature: json['servo_config_feature'] as bool? ?? true,
      oledConnected: json['oled_connected'] as bool? ?? false,
      activeRelays: activeRelayList,
      activeSwitches: activeSwitchList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_name': deviceName,
      'version': version,
      'relays_count': relaysCount,
      'switches_count': switchesCount,
      'servos_count': servosCount,
      'timer_feature': timerFeature,
      'max_timers': maxTimers,
      'scheduler_feature': schedulerFeature,
      'max_schedules': maxSchedules,
      'servo_config_feature': servoConfigFeature,
      'oled_connected': oledConnected,
      'active_relays': activeRelays,
      'active_switches': activeSwitches,
    };
  }

  // Save capabilities to SharedPreferences
  Future<void> saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_esp_capabilities', jsonEncode(toJson()));
  }

  // Load capabilities from SharedPreferences
  static Future<EspCapabilities?> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_esp_capabilities');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return EspCapabilities.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  /// Check if a specific relay index (0-based) is active
  bool isRelayActive(int index) {
    if (index < 0 || index >= activeRelays.length) return false;
    return activeRelays[index];
  }

  /// Check if a specific switch index (0-based) is active
  bool isSwitchActive(int index) {
    if (index < 0 || index >= activeSwitches.length) return false;
    return activeSwitches[index];
  }

  /// Whether there is at least one active relay
  bool get hasAnyRelay => relaysCount > 0;

  /// Whether there is at least one active switch/servo
  bool get hasAnySwitch => switchesCount > 0;

  /// Whether there is any controllable device
  bool get hasAnyDevice => hasAnyRelay || hasAnySwitch;
}
