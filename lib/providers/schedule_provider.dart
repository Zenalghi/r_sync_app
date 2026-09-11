import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/schedule_job.dart';
import '../services/api_service.dart';
import 'esp_provider.dart';

/// Provider for managing Smart Scheduling logic for ESP32 Relay 1 and Relay 2.
/// Directly synchronizes with EspProvider so incoming jobs are immediately reflected
/// across all screens without manual intervention.
class ScheduleProvider extends ChangeNotifier {
  final ApiService _apiService;
  EspProvider? _espProvider;

  static const int maxJobs = 4;

  List<ScheduleJob> _jobs1 = [];
  List<ScheduleJob> _jobs2 = [];
  bool _isSaving = false;
  String? _errorMessage;

  ScheduleProvider(this._apiService, [this._espProvider]) {
    _bindEspProvider();
  }

  void updateEspProvider(EspProvider espProvider) {
    if (_espProvider == espProvider) return;
    _espProvider?.removeListener(_onEspStatusChanged);
    _espProvider = espProvider;
    _bindEspProvider();
  }

  void _bindEspProvider() {
    if (_espProvider == null) return;
    _espProvider!.addListener(_onEspStatusChanged);
    // Initial sync
    _onEspStatusChanged();
  }

  void _onEspStatusChanged() {
    if (_isSaving || _espProvider == null) return;
    updateFromEspStatus(
      _espProvider!.status.jobs1,
      _espProvider!.status.jobs2,
    );
  }

  List<ScheduleJob> get jobs1 => List.unmodifiable(_jobs1);
  List<ScheduleJob> get jobs2 => List.unmodifiable(_jobs2);
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Returns configured jobs for a specific channel (1 or 2)
  List<ScheduleJob> getJobs(int channel) {
    return channel == 1 ? _jobs1 : _jobs2;
  }

  /// Whether a new schedule can be added to the channel
  bool canAddJob(int channel) {
    return getJobs(channel).length < maxJobs;
  }

  /// Synchronizes incoming ESP32 status jobs into the smart scheduler
  void updateFromEspStatus(
      List<ScheduleJob> espJobs1, List<ScheduleJob> espJobs2) {
    if (_isSaving) return;

    // Filter out blank/empty slots from ESP32 so only configured schedules appear in the UI
    final newJobs1 = espJobs1
        .where((j) => j.enabled || j.hour != 0 || j.minute != 0)
        .toList()
      ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    final newJobs2 = espJobs2
        .where((j) => j.enabled || j.hour != 0 || j.minute != 0)
        .toList()
      ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    if (!listEquals(_jobs1, newJobs1) || !listEquals(_jobs2, newJobs2)) {
      _jobs1 = newJobs1;
      _jobs2 = newJobs2;
      notifyListeners();
    }
  }

  /// Smart suggestion: Alternates action based on the previous job
  /// If previous job was 'ON' -> suggest 'OFF'
  /// If previous job was 'OFF' -> suggest 'ON'
  /// If no jobs exist -> suggest 'ON'
  String getNextRecommendedAction(int channel) {
    final currentJobs = getJobs(channel);
    if (currentJobs.isEmpty) return 'ON';

    final lastJob = currentJobs.last;
    return lastJob.isActionOn ? 'OFF' : 'ON';
  }

  /// Smart suggestion for new schedule time:
  /// Defaults to 1 hour after the latest scheduled job, or current time + 15 mins
  TimeOfDay getNextRecommendedTime(int channel) {
    final currentJobs = getJobs(channel);
    if (currentJobs.isEmpty) {
      final now = DateTime.now();
      final target = now.add(const Duration(minutes: 15));
      return TimeOfDay(hour: target.hour, minute: target.minute);
    }

    final lastJob = currentJobs.last;
    final nextMinutes = (lastJob.totalMinutes + 60) % (24 * 60);
    return TimeOfDay(hour: nextMinutes ~/ 60, minute: nextMinutes % 60);
  }

  /// Adds a new schedule job to channel and syncs with ESP32
  Future<bool> addJob({
    required String espIp,
    required int channel,
    required ScheduleJob newJob,
  }) async {
    final currentList = List<ScheduleJob>.from(getJobs(channel));
    if (currentList.length >= maxJobs) {
      _errorMessage = 'Maksimal $maxJobs jadwal per relay!';
      notifyListeners();
      return false;
    }

    currentList.add(newJob);
    currentList.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    return _syncWithEsp(espIp, channel, currentList);
  }

  /// Updates an existing schedule job and syncs with ESP32
  Future<bool> updateJob({
    required String espIp,
    required int channel,
    required int index,
    required ScheduleJob updatedJob,
  }) async {
    final currentList = List<ScheduleJob>.from(getJobs(channel));
    if (index < 0 || index >= currentList.length) return false;

    currentList[index] = updatedJob;
    currentList.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    return _syncWithEsp(espIp, channel, currentList);
  }

  /// Toggles enabled state of a job and syncs with ESP32
  Future<bool> toggleJobEnabled({
    required String espIp,
    required int channel,
    required int index,
  }) async {
    final currentList = List<ScheduleJob>.from(getJobs(channel));
    if (index < 0 || index >= currentList.length) return false;

    final targetJob = currentList[index];
    currentList[index] = targetJob.copyWith(enabled: !targetJob.enabled);

    return _syncWithEsp(espIp, channel, currentList);
  }

  /// Deletes a job from channel and syncs with ESP32
  Future<bool> deleteJob({
    required String espIp,
    required int channel,
    required int index,
  }) async {
    final currentList = List<ScheduleJob>.from(getJobs(channel));
    if (index < 0 || index >= currentList.length) return false;

    currentList.removeAt(index);

    return _syncWithEsp(espIp, channel, currentList);
  }

  /// Synchronizes full 4-slot array to ESP32 to prevent ghost schedules in memory
  Future<bool> _syncWithEsp(
    String espIp,
    int channel,
    List<ScheduleJob> newList,
  ) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.saveSchedule(espIp, channel, newList);
      if (success) {
        if (channel == 1) {
          _jobs1 = newList;
        } else {
          _jobs2 = newList;
        }
        // Notify EspProvider to refresh authoritative status from ESP32
        _espProvider?.refreshStatus();
        return true;
      } else {
        _errorMessage = 'Gagal menyimpan jadwal ke ESP32';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _espProvider?.removeListener(_onEspStatusChanged);
    super.dispose();
  }
}
