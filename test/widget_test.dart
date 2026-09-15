import 'package:flutter_test/flutter_test.dart';
import 'package:r_sync_app/models/esp_status.dart';
import 'package:r_sync_app/models/schedule_job.dart';
import 'package:r_sync_app/providers/schedule_provider.dart';
import 'package:r_sync_app/services/api_service.dart';
import 'package:r_sync_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScheduleJob Model Tests', () {
    test('Correctly serializes and deserializes ESP32 JSON', () {
      final json = {
        'h': 14,
        'm': 45,
        'a': 'ON',
        'e': true,
      };

      final job = ScheduleJob.fromJson(json);
      expect(job.hour, 14);
      expect(job.minute, 45);
      expect(job.action, 'ON');
      expect(job.enabled, true);
      expect(job.timeString, '14:45');
      expect(job.isActionOn, true);
      expect(job.totalMinutes, 14 * 60 + 45);

      final outJson = job.toJson();
      expect(outJson['h'], 14);
      expect(outJson['m'], 45);
      expect(outJson['a'], 'ON');
      expect(outJson['e'], true);
    });

    test('Identifies empty/unconfigured slots', () {
      final emptyJob = ScheduleJob.empty();
      expect(emptyJob.isEmptySlot, true);
      expect(emptyJob.enabled, false);
      expect(emptyJob.action, 'OFF');

      const configuredJob = ScheduleJob(
        hour: 8,
        minute: 0,
        action: 'ON',
        enabled: true,
      );
      expect(configuredJob.isEmptySlot, false);
    });
  });

  group('EspStatus Model Tests', () {
    test('Parses ESP32 GET /api/status JSON', () {
      final json = {
        'ip': '192.168.4.1',
        'wifi': 'Connected',
        'time': '2026-09-11 12:30:00',
        'relay1': 'ON',
        'relay2': 'OFF',
        'displayPage': 1,
        'activeLow': false,
        'jobs1': [
          {'h': 8, 'm': 0, 'a': 'ON', 'e': true},
          {'h': 18, 'm': 0, 'a': 'OFF', 'e': true},
          {'h': 0, 'm': 0, 'a': 'OFF', 'e': false},
          {'h': 0, 'm': 0, 'a': 'OFF', 'e': false},
        ],
        'jobs2': [
          {'h': 0, 'm': 0, 'a': 'OFF', 'e': false},
          {'h': 0, 'm': 0, 'a': 'OFF', 'e': false},
          {'h': 0, 'm': 0, 'a': 'OFF', 'e': false},
          {'h': 0, 'm': 0, 'a': 'OFF', 'e': false},
        ],
      };

      final status = EspStatus.fromJson(json);
      expect(status.ip, '192.168.4.1');
      expect(status.isWifiConnected, true);
      expect(status.relay1, true);
      expect(status.relay2, false);
      expect(status.displayPage, 1);
      expect(status.activeLow, false);
      expect(status.jobs1.length, 4);
      expect(status.jobs2.length, 4);
      expect(status.getRelayState(1), true);
      expect(status.getRelayState(2), false);

      final nextJob = status.getNextActiveJob(1);
      expect(nextJob, isNotNull);
    });
  });

  group('StorageService Tests', () {
    test('Sets and gets ESP IP & defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      expect(storage.getEspIp(), StorageService.defaultEspIp);

      await storage.setEspIp('192.168.1.120');
      expect(storage.getEspIp(), '192.168.1.120');
    });
  });

  group('ScheduleProvider Smart Logic Tests', () {
    test('Recommends smart alternating actions (empty -> ON, ON -> OFF, OFF -> ON)', () {
      // Mock ApiService
      final scheduleProvider = ScheduleProvider(ApiService());

      // 1. Initially empty -> should recommend ON
      expect(scheduleProvider.getNextRecommendedAction(1), 'ON');

      // 2. Simulate status update with job1 = 08:00 ON
      scheduleProvider.updateFromEspStatus([
        const ScheduleJob(hour: 8, minute: 0, action: 'ON', enabled: true),
        ScheduleJob.empty(),
        ScheduleJob.empty(),
        ScheduleJob.empty(),
      ], []);

      // Now last job was ON -> should recommend OFF!
      expect(scheduleProvider.getNextRecommendedAction(1), 'OFF');
      expect(scheduleProvider.getJobs(1).length, 1);

      // 3. Simulate status update with second job = 12:00 OFF
      scheduleProvider.updateFromEspStatus([
        const ScheduleJob(hour: 8, minute: 0, action: 'ON', enabled: true),
        const ScheduleJob(hour: 12, minute: 0, action: 'OFF', enabled: true),
        ScheduleJob.empty(),
        ScheduleJob.empty(),
      ], []);

      // Now last job was OFF -> should recommend ON!
      expect(scheduleProvider.getNextRecommendedAction(1), 'ON');
      expect(scheduleProvider.getJobs(1).length, 2);

      // 4. Test capacity: 2 jobs used, can still add
      expect(scheduleProvider.canAddJob(1), true);

      // 5. Simulate 4 jobs loaded
      scheduleProvider.updateFromEspStatus([
        const ScheduleJob(hour: 8, minute: 0, action: 'ON', enabled: true),
        const ScheduleJob(hour: 12, minute: 0, action: 'OFF', enabled: true),
        const ScheduleJob(hour: 14, minute: 0, action: 'ON', enabled: true),
        const ScheduleJob(hour: 18, minute: 0, action: 'OFF', enabled: true),
      ], []);

      expect(scheduleProvider.getJobs(1).length, 4);
      expect(scheduleProvider.canAddJob(1), false);
    });

    test('Automatically parses and displays configured schedules (e.g. 17:30 ON)', () {
      final scheduleProvider = ScheduleProvider(ApiService());

      // Simulate incoming status from ESP32 containing 17:30 ON in slot 0, and slot 1..3 empty
      scheduleProvider.updateFromEspStatus([
        const ScheduleJob(hour: 17, minute: 30, action: 'ON', enabled: true),
        ScheduleJob.empty(),
        ScheduleJob.empty(),
        ScheduleJob.empty(),
      ], []);

      // Verifies that slot 0 is retained and empty slots are filtered out
      expect(scheduleProvider.getJobs(1).length, 1);
      expect(scheduleProvider.getJobs(1).first.timeString, '17:30');
      expect(scheduleProvider.getJobs(1).first.action, 'ON');
      expect(scheduleProvider.getJobs(1).first.enabled, true);

      // Smart recommendation for next job should now be OFF
      expect(scheduleProvider.getNextRecommendedAction(1), 'OFF');
    });
  });
}
