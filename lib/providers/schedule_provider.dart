// lib/providers/schedule_provider.dart

import 'package:flutter/material.dart';
import '../models/schedule_job.dart';
import '../services/api_service.dart';
import 'esp_provider.dart';

/// Provider for managing Smart Scheduling logic for all ESP32 channels (4 Relays + 3 Servo Wall Switches = 7 channels).
class ScheduleProvider extends ChangeNotifier {
  final ApiService _apiService;
  EspProvider? _espProvider;

  static const int maxJobs = 4;

  final Map<int, List<ScheduleJob>> _channelJobs = {};
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
    _onEspStatusChanged();
  }

  void _onEspStatusChanged() {
    if (_isSaving || _espProvider == null) return;
    updateFromEspStatus(
      _espProvider!.status.jobs1,
      _espProvider!.status.jobs2,
    );
  }

  void updateFromEspStatus(List<ScheduleJob> j1, List<ScheduleJob> j2) {
    if (_isSaving) return;
    _channelJobs[0] = j1.where((j) => j.enabled || j.hour != 0 || j.minute != 0).toList()
      ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    _channelJobs[1] = j2.where((j) => j.enabled || j.hour != 0 || j.minute != 0).toList()
      ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    notifyListeners();
  }

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<ScheduleJob> getJobs(int channel) {
    final key = (channel >= 1) ? channel - 1 : channel;
    return List.unmodifiable(_channelJobs[key] ?? []);
  }

  bool canAddJob(int channel) {
    return getJobs(channel).length < maxJobs;
  }

  String getNextRecommendedAction(int channel) {
    final currentJobs = getJobs(channel);
    if (currentJobs.isEmpty) return 'ON';
    final lastJob = currentJobs.last;
    return lastJob.isActionOn ? 'OFF' : 'ON';
  }

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

  Future<bool> addJob({
    required String espIp,
    required int channel,
    required ScheduleJob newJob,
  }) async {
    final currentList = List<ScheduleJob>.from(getJobs(channel));
    if (currentList.length >= maxJobs) {
      _errorMessage = 'Maksimal $maxJobs jadwal!';
      notifyListeners();
      return false;
    }
    currentList.add(newJob);
    currentList.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    return _syncWithEsp(espIp, channel, currentList);
  }

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

  Future<bool> _syncWithEsp(
    String espIp,
    int channel,
    List<ScheduleJob> newList,
  ) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final key = (channel >= 1) ? channel - 1 : channel;

    try {
      final success = await _apiService.saveSchedule(espIp, key, newList);
      if (success) {
        _channelJobs[key] = newList;
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
