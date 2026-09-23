// lib/models/esp_capabilities.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents hardware and software capabilities discovered from ESP32 (`GET /api/capabilities`).
class EspCapabilities {
  final String deviceName;
  final String version;
  final int relaysCount;
  final int switchesCount;
  final int servosCount;
  final bool timerFeature;
  final int maxTimers;
  final bool schedulerFeature;
  final int maxSchedulesPerChannel;
  final bool servoConfigFeature;

  const EspCapabilities({
    this.deviceName = 'R-Sync ESP32 Server',
    this.version = '2.0.0',
    this.relaysCount = 4,
    this.switchesCount = 3,
    this.servosCount = 6,
    this.timerFeature = true,
    this.maxTimers = 10,
    this.schedulerFeature = true,
    this.maxSchedulesPerChannel = 4,
    this.servoConfigFeature = true,
  });

  factory EspCapabilities.initial() {
    return const EspCapabilities();
  }

  factory EspCapabilities.fromJson(Map<String, dynamic> json) {
    return EspCapabilities(
      deviceName: json['device_name'] as String? ?? 'R-Sync ESP32 Server',
      version: json['version'] as String? ?? '2.0.0',
      relaysCount: json['relays_count'] as int? ?? 4,
      switchesCount: json['switches_count'] as int? ?? 3,
      servosCount: json['servos_count'] as int? ?? 6,
      timerFeature: json['timer_feature'] as bool? ?? true,
      maxTimers: json['max_timers'] as int? ?? 10,
      schedulerFeature: json['scheduler_feature'] as bool? ?? true,
      maxSchedulesPerChannel: json['max_schedules_per_channel'] as int? ?? 4,
      servoConfigFeature: json['servo_config_feature'] as bool? ?? true,
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
      'max_schedules_per_channel': maxSchedulesPerChannel,
      'servo_config_feature': servoConfigFeature,
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
}
