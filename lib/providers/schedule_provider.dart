// lib/providers/schedule_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_job.dart';
import '../services/api_service.dart';
import 'esp_provider.dart';

/// Provider for managing global Smart Scheduling (v2 — multi-channel per entry).
/// Schedules are synced with ESP32 and also cached locally in SharedPreferences.
class ScheduleProvider extends ChangeNotifier {
  final ApiService _apiService;
  EspProvider? _espProvider;

  static const int maxSchedules = 10;
  static const String _localCacheKey = 'cached_schedules_v2';

  List<ScheduleJob> _schedules = [];
  bool _isSaving = false;
  String? _errorMessage;

  ScheduleProvider(this._apiService, [this._espProvider]) {
    _bindEspProvider();
    _loadLocalCache();
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
    final espSchedules = _espProvider!.status.schedules;
    if (espSchedules.isNotEmpty) {
      _schedules = List<ScheduleJob>.from(espSchedules)
        ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
      _saveLocalCache();
      notifyListeners();
    }
  }

  /// Load from local SharedPreferences cache (offline support)
  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_localCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        final loaded = list
            .map((item) => ScheduleJob.fromJson(item as Map<String, dynamic>))
            .where((j) => j.enabled || j.hour != 0 || j.minute != 0)
            .toList()
          ..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
        if (loaded.isNotEmpty && _schedules.isEmpty) {
          _schedules = loaded;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Save current schedules to local SharedPreferences cache
  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_schedules.map((j) => j.toJson()).toList());
      await prefs.setString(_localCacheKey, jsonStr);
    } catch (_) {}
  }

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<ScheduleJob> get schedules => List.unmodifiable(_schedules);
  int get count => _schedules.length;
  bool get canAdd => _schedules.length < maxSchedules;

  Future<bool> addSchedule({
    required String espIp,
    required ScheduleJob newJob,
  }) async {
    if (_schedules.length >= maxSchedules) {
      _errorMessage = 'Maksimal $maxSchedules jadwal sudah tercapai!';
      notifyListeners();
      return false;
    }
    final newList = List<ScheduleJob>.from(_schedules)..add(newJob);
    newList.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    return _syncWithEsp(espIp, newList);
  }

  Future<bool> updateSchedule({
    required String espIp,
    required int index,
    required ScheduleJob updatedJob,
  }) async {
    if (index < 0 || index >= _schedules.length) return false;
    final newList = List<ScheduleJob>.from(_schedules);
    newList[index] = updatedJob;
    newList.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    return _syncWithEsp(espIp, newList);
  }

  Future<bool> toggleScheduleEnabled({
    required String espIp,
    required int index,
  }) async {
    if (index < 0 || index >= _schedules.length) return false;
    final newList = List<ScheduleJob>.from(_schedules);
    newList[index] = newList[index].copyWith(enabled: !newList[index].enabled);
    return _syncWithEsp(espIp, newList);
  }

  Future<bool> deleteSchedule({
    required String espIp,
    required int index,
  }) async {
    if (index < 0 || index >= _schedules.length) return false;
    final newList = List<ScheduleJob>.from(_schedules)..removeAt(index);
    return _syncWithEsp(espIp, newList);
  }

  Future<bool> _syncWithEsp(String espIp, List<ScheduleJob> newList) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.saveAllSchedules(
        espIp,
        newList,
        maxSlots: maxSchedules,
      );
      if (success) {
        _schedules = newList;
        await _saveLocalCache();
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

  /// Suggest next recommended action based on existing schedules
  String getNextRecommendedAction() {
    if (_schedules.isEmpty) return 'ON';
    final last = _schedules.last;
    return last.isActionOn ? 'OFF' : 'ON';
  }

  /// Suggest next recommended time (last schedule + 1 hour)
  TimeOfDay getNextRecommendedTime() {
    if (_schedules.isEmpty) {
      final now = DateTime.now();
      final target = now.add(const Duration(minutes: 15));
      return TimeOfDay(hour: target.hour, minute: target.minute);
    }
    final last = _schedules.last;
    final nextMinutes = (last.totalMinutes + 60) % (24 * 60);
    return TimeOfDay(hour: nextMinutes ~/ 60, minute: nextMinutes % 60);
  }

  @override
  void dispose() {
    _espProvider?.removeListener(_onEspStatusChanged);
    super.dispose();
  }
}
