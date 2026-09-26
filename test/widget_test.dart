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
      final json = {'h': 14, 'm': 45, 'a': 'ON', 'e': true};

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

    test('Identifies empty/unconfigured target lists', () {
      final emptyJob = ScheduleJob.empty();
      expect(emptyJob.hasNoTargets, true);
      expect(emptyJob.enabled, false);
      expect(emptyJob.action, 'OFF');

      final configuredJob = ScheduleJob(
        hour: 8,
        minute: 0,
        action: 'ON',
        enabled: true,
        targetRelays: [true, false, false, false],
        targetSwitches: [false, false, false],
      );
      expect(configuredJob.hasNoTargets, false);
    });
  });

  group('EspStatus Model Tests', () {
    test('Parses ESP32 GET /api/status JSON', () {
      final json = {
        'ip': '192.168.4.1',
        'wifi': 'Connected',
        'time': '2026-09-11 12:30:00',
        'relays': ['ON', 'OFF'],
        'switches': ['OFF', 'OFF', 'OFF'],
        'displayPage': 1,
        'activeLow': false,
        'schedules': [
          {
            'h': 8,
            'm': 0,
            'a': 'ON',
            'e': true,
            'r': [true, false],
            's': [false, false, false],
          },
          {
            'h': 18,
            'm': 0,
            'a': 'OFF',
            'e': true,
            'r': [true, false],
            's': [false, false, false],
          },
        ],
      };

      final status = EspStatus.fromJson(json);
      expect(status.ip, '192.168.4.1');
      expect(status.isWifiConnected, true);
      expect(status.getRelayState(1), true);
      expect(status.getRelayState(2), false);
      expect(status.displayPage, 1);
      expect(status.activeLow, false);
      expect(status.schedules.length, 2);

      final nextJob = status.getNextActiveJobForRelay(1);
      expect(nextJob, isNotNull);
      expect(nextJob!.timeString, '08:00');
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
    ScheduleJob makeJob(int hour, int minute, String action) => ScheduleJob(
      hour: hour,
      minute: minute,
      action: action,
      enabled: true,
      targetRelays: const [true, false, false, false],
      targetSwitches: const [false, false, false],
    );

    test('Recommends smart alternating actions (empty -> ON, ON -> OFF, OFF -> ON)', () async {
      SharedPreferences.setMockInitialValues({});
      final scheduleProvider = ScheduleProvider(_FakeApiService());

      // 1. Initially empty -> should recommend ON
      expect(scheduleProvider.getNextRecommendedAction(), 'ON');

      // 2. Add job at 08:00 ON
      await scheduleProvider.addSchedule(
        espIp: '192.168.4.1',
        newJob: makeJob(8, 0, 'ON'),
      );

      // Last job was ON -> should recommend OFF!
      expect(scheduleProvider.getNextRecommendedAction(), 'OFF');
      expect(scheduleProvider.schedules.length, 1);

      // 3. Add job at 12:00 OFF
      await scheduleProvider.addSchedule(
        espIp: '192.168.4.1',
        newJob: makeJob(12, 0, 'OFF'),
      );

      // Last job was OFF -> should recommend ON!
      expect(scheduleProvider.getNextRecommendedAction(), 'ON');
      expect(scheduleProvider.schedules.length, 2);

      // 4. Still under capacity
      expect(scheduleProvider.canAdd, true);
    });

    test('Enforces max schedule capacity', () async {
      SharedPreferences.setMockInitialValues({});
      final scheduleProvider = ScheduleProvider(_FakeApiService());

      for (int i = 0; i < ScheduleProvider.maxSchedules; i++) {
        final ok = await scheduleProvider.addSchedule(
          espIp: '192.168.4.1',
          newJob: makeJob(i, 0, i.isEven ? 'ON' : 'OFF'),
        );
        expect(ok, true);
      }

      expect(scheduleProvider.schedules.length, ScheduleProvider.maxSchedules);
      expect(scheduleProvider.canAdd, false);

      final rejected = await scheduleProvider.addSchedule(
        espIp: '192.168.4.1',
        newJob: makeJob(23, 0, 'ON'),
      );
      expect(rejected, false);
    });

    test('Deletes a schedule entry', () async {
      SharedPreferences.setMockInitialValues({});
      final scheduleProvider = ScheduleProvider(_FakeApiService());

      await scheduleProvider.addSchedule(
        espIp: '192.168.4.1',
        newJob: makeJob(17, 30, 'ON'),
      );
      expect(scheduleProvider.schedules.length, 1);
      expect(scheduleProvider.schedules.first.timeString, '17:30');

      final deleted = await scheduleProvider.deleteSchedule(
        espIp: '192.168.4.1',
        index: 0,
      );
      expect(deleted, true);
      expect(scheduleProvider.schedules, isEmpty);
    });
  });
}

/// Fake ApiService that simulates successful ESP32 sync without networking.
class _FakeApiService extends ApiService {
  @override
  Future<bool> saveAllSchedules(
    String ip,
    List<ScheduleJob> schedules, {
    int maxSlots = 10,
  }) async {
    return true;
  }
}
