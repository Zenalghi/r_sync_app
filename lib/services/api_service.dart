// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/esp_capabilities.dart';
import '../models/esp_status.dart';
import '../models/schedule_job.dart';

/// Exception thrown when API call to ESP32 fails
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Service handling all HTTP REST API calls to the ESP32 local server.
class ApiService {
  final http.Client _client;
  static const Duration defaultTimeout = Duration(seconds: 4);

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Clean IP string by removing protocol prefixes and trailing slashes
  String _formatBaseUrl(String rawIp) {
    var clean = rawIp.trim();
    if (clean.startsWith('http://')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('https://')) {
      clean = clean.substring(8);
    }
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return 'http://$clean';
  }

  Map<String, String> get _postHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
      };

  /// Fetches system capabilities from `GET /api/capabilities`
  Future<EspCapabilities> getCapabilities(String ip) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/capabilities');

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json, */*'})
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final caps = EspCapabilities.fromJson(data);
        await caps.saveToLocal(); // Save capabilities to SharedPreferences
        return caps;
      } else {
        return EspCapabilities.initial();
      }
    } catch (_) {
      // Return saved capabilities or initial default if offline
      final local = await EspCapabilities.loadFromLocal();
      return local ?? EspCapabilities.initial();
    }
  }

  /// Fetches system status, relays, switches, and timers from `GET /api/status`
  Future<EspStatus> getStatus(String ip) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/status');

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json, */*'})
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EspStatus.fromJson(data);
      } else {
        throw ApiException(
          'Failed to get status from ESP32',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException('Connection timed out connecting to ESP32 ($ip)');
    } on FormatException {
      throw ApiException('Invalid JSON response from ESP32');
    } on http.ClientException catch (e) {
      throw ApiException('Network connection failed ($ip): ${e.message}');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// Sets relay state via `POST /api/relay`
  Future<bool> setRelay(String ip, int channel, bool state) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/relay');
    final payload = {'channel': channel, 'state': state ? 'ON' : 'OFF'};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService setRelay error: $e');
      return false;
    }
  }

  /// Sets switch state via `POST /api/switch` (switchIdx: 0=A, 1=B, 2=C)
  Future<bool> setSwitch(String ip, int switchIdx, bool state) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/switch');
    final payload = {'switch': switchIdx, 'state': state ? 'ON' : 'OFF'};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService setSwitch error: $e');
      return false;
    }
  }

  /// Triggers servo self test via `POST /api/servo/test`
  Future<bool> triggerServoTest(String ip) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/servo/test');
    try {
      final response = await _client
          .post(uri, headers: _postHeaders)
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Configures servo calibration angles via `POST /api/servo/config`
  Future<bool> setServoConfig(
    String ip, {
    required int restAngle,
    required int pressAngle,
    required int pressDurationMs,
  }) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/servo/config');
    final payload = {
      'restAngle': restAngle,
      'pressAngle': pressAngle,
      'pressDurationMs': pressDurationMs,
    };

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Adds countdown timer via `POST /api/timer/add`
  Future<bool> addTimer(
    String ip, {
    required int durationSec,
    required bool invertOnStartEnd,
    required String targetAction,
    required List<bool> targetRelays,
    required List<bool> targetSwitches,
  }) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/timer/add');
    final payload = {
      'durationSec': durationSec,
      'invertOnStartEnd': invertOnStartEnd,
      'targetAction': targetAction,
      'targetRelays': targetRelays,
      'targetSwitches': targetSwitches,
    };

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Controls active timer (pause, resume, cancel) via `POST /api/timer/control`
  Future<bool> controlTimer(String ip, int timerId, String command) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/timer/control');
    final payload = {'id': timerId, 'command': command};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sends updated schedule jobs via `POST /api/schedule`
  Future<bool> saveSchedule(
    String ip,
    int channel,
    List<ScheduleJob> jobs,
  ) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/schedule');

    final List<Map<String, dynamic>> serializedJobs = [];
    for (int i = 0; i < 4; i++) {
      if (i < jobs.length) {
        serializedJobs.add(jobs[i].toJson());
      } else {
        serializedJobs.add(ScheduleJob.empty().toJson());
      }
    }

    final payload = {'channel': channel, 'jobs': serializedJobs};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Changes OLED display page via `POST /api/display`
  Future<int?> setDisplayPage(String ip, [int? page]) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/display');

    final payload = <String, dynamic>{};
    if (page != null && page >= 0) {
      payload['page'] = page;
    }

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data['displayPage'] != null) {
              return (data['displayPage'] as num).toInt();
            }
          } catch (_) {}
        }
        return page ?? 0;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Triggers WiFi Reset
  Future<bool> resetWifi(String ip) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/wifi/reset');
    try {
      final response = await _client
          .post(uri, headers: _postHeaders)
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sets relay active polarity
  Future<bool> setRelayPolarity(String ip, bool activeLow) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/relay/polarity');
    final payload = {'activeLow': activeLow};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Quick connectivity ping test
  Future<bool> testConnection(String ip) async {
    try {
      final status = await getStatus(ip);
      return status.ip.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
