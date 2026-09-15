//lib\services\api_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  /// On Web, use text/plain to avoid browser CORS preflight (OPTIONS) requirements.
  /// ESP32 parses raw JSON bytes directly regardless of Content-Type.
  Map<String, String> get _postHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/plain, */*',
  };

  /// Fetches system status, relays, and jobs from `GET /api/status`
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
  /// channel: 1 or 2
  /// state: true for ON, false for OFF
  Future<bool> setRelay(String ip, int channel, bool state) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/relay');

    final payload = {'channel': channel, 'state': state ? 'ON' : 'OFF'};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return true;
        try {
          final data = jsonDecode(response.body);
          if (data is Map) {
            return data['status'] == 'OK' || data['status'] == true;
          }
          return true;
        } catch (_) {
          // If status code is 200 OK, treat as successful even if body is plaintext
          return true;
        }
      }
      return false;
    } on TimeoutException {
      throw ApiException('Relay command timed out');
    } on http.ClientException catch (e) {
      debugPrint('ApiService setRelay ClientException: $e');
      throw ApiException('Cannot reach ESP32 ($ip): ${e.message}');
    } catch (e) {
      debugPrint('ApiService setRelay error: $e');
      throw ApiException('Failed to set relay: $e');
    }
  }

  /// Sends updated schedule jobs via `POST /api/schedule`
  /// Pads with empty/disabled jobs up to 4 slots to ensure ESP32 flash memory is synchronized.
  Future<bool> saveSchedule(
    String ip,
    int channel,
    List<ScheduleJob> jobs,
  ) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/schedule');

    // ESP32 supports MAX_JOBS = 4. Pad array with disabled jobs if fewer than 4.
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

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return true;
        try {
          final data = jsonDecode(response.body);
          if (data is Map) {
            return data['status'] == 'OK' || data['status'] == true;
          }
          return true;
        } catch (_) {
          return true;
        }
      }
      return false;
    } on TimeoutException {
      throw ApiException('Save schedule timed out');
    } on http.ClientException catch (e) {
      debugPrint('ApiService saveSchedule ClientException: $e');
      throw ApiException('Cannot reach ESP32 ($ip): ${e.message}');
    } catch (e) {
      debugPrint('ApiService saveSchedule error: $e');
      throw ApiException('Failed to save schedule: $e');
    }
  }

  /// Changes or toggles the OLED display page on ESP32 via `POST /api/display`
  /// If [page] is null or negative, ESP32 toggles to the next page.
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
    } on TimeoutException {
      throw ApiException('Display switch timed out');
    } on http.ClientException catch (e) {
      debugPrint('ApiService setDisplayPage ClientException: $e');
      throw ApiException('Cannot reach ESP32 ($ip): ${e.message}');
    } catch (e) {
      debugPrint('ApiService setDisplayPage error: $e');
      throw ApiException('Failed to set OLED display page: $e');
    }
  }

  /// Triggers ESP32 to clear stored Wi-Fi credentials and launch Config Portal 'R-Sync'
  Future<bool> resetWifi(String ip) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/wifi/reset');
    try {
      final response = await _client
          .post(uri, headers: _postHeaders)
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService resetWifi error: $e');
      return false;
    }
  }

  /// Sets relay active polarity (activeLow: true for Active LOW, false for Active HIGH)
  /// ESP32 resets relays to OFF state when polarity changes.
  Future<bool> setRelayPolarity(String ip, bool activeLow) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/relay/polarity');

    final payload = {'activeLow': activeLow};

    try {
      final response = await _client
          .post(uri, headers: _postHeaders, body: jsonEncode(payload))
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return true;
        try {
          final data = jsonDecode(response.body);
          if (data is Map) {
            return data['status'] == 'OK';
          }
          return true;
        } catch (_) {
          return true;
        }
      }
      return false;
    } on TimeoutException {
      throw ApiException('Polarity change timed out');
    } on http.ClientException catch (e) {
      debugPrint('ApiService setRelayPolarity ClientException: $e');
      throw ApiException('Cannot reach ESP32 ($ip): ${e.message}');
    } catch (e) {
      debugPrint('ApiService setRelayPolarity error: $e');
      throw ApiException('Failed to set relay polarity: $e');
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
