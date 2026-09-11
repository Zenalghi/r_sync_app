import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  /// Fetches system status, relays, and jobs from `GET /api/status`
  Future<EspStatus> getStatus(String ip) async {
    final baseUrl = _formatBaseUrl(ip);
    final uri = Uri.parse('$baseUrl/api/status');

    try {
      final response = await _client.get(uri).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EspStatus.fromJson(data);
      } else {
        throw ApiException(
          'Failed to get status from ESP32',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException('Cannot reach ESP32 ($ip): ${e.message}');
    } on TimeoutException {
      throw ApiException('Connection timed out connecting to ESP32 ($ip)');
    } on FormatException {
      throw ApiException('Invalid JSON response from ESP32');
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

    final payload = {
      'channel': channel,
      'state': state ? 'ON' : 'OFF',
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'OK';
      }
      return false;
    } on SocketException catch (e) {
      throw ApiException('Cannot reach ESP32: ${e.message}');
    } on TimeoutException {
      throw ApiException('Relay command timed out');
    } catch (e) {
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

    final payload = {
      'channel': channel,
      'jobs': serializedJobs,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'OK';
      }
      return false;
    } on SocketException catch (e) {
      throw ApiException('Cannot reach ESP32: ${e.message}');
    } on TimeoutException {
      throw ApiException('Save schedule timed out');
    } catch (e) {
      throw ApiException('Failed to save schedule: $e');
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
