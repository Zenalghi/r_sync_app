// lib/providers/esp_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/esp_capabilities.dart';
import '../models/esp_status.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class EspProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  late String _espIp;
  EspStatus _status = EspStatus.initial();
  EspCapabilities _capabilities = EspCapabilities.initial();
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;
  late bool _autoRefresh;
  late int _pollInterval;

  EspProvider(this._apiService, this._storageService) {
    _espIp = _storageService.getEspIp();
    _autoRefresh = _storageService.getAutoRefresh();
    _pollInterval = _storageService.getPollInterval();

    // Load cached capabilities from SharedPreferences on app startup
    _loadCachedCapabilities();

    // Initial fetch
    refreshStatus();
    if (_autoRefresh) {
      _startPolling();
    }
  }

  String get espIp => _espIp;
  EspStatus get status => _status;
  EspCapabilities get capabilities => _capabilities;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get autoRefresh => _autoRefresh;
  int get pollInterval => _pollInterval;

  Future<void> _loadCachedCapabilities() async {
    final cached = await EspCapabilities.loadFromLocal();
    if (cached != null) {
      _capabilities = cached;
      notifyListeners();
    }
  }

  Future<void> setEspIp(String newIp) async {
    final cleanIp = newIp.trim();
    if (cleanIp.isEmpty || cleanIp == _espIp) return;

    _espIp = cleanIp;
    await _storageService.setEspIp(cleanIp);
    notifyListeners();

    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Discover capabilities
      final newCaps = await _apiService.getCapabilities(_espIp);
      _capabilities = newCaps;

      // Fetch status
      final newStatus = await _apiService.getStatus(_espIp);
      _status = newStatus;
      _isConnected = true;
      _errorMessage = null;
    } catch (e) {
      _isConnected = false;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleRelay(int channel) async {
    final currentState = _status.getRelayState(channel);
    final targetState = !currentState;

    // Optimistic UI update
    final updatedRelays = List<bool>.from(_status.relays);
    if (channel - 1 < updatedRelays.length) {
      updatedRelays[channel - 1] = targetState;
    }
    _status = _status.copyWith(relays: updatedRelays);
    notifyListeners();

    try {
      final success = await _apiService.setRelay(_espIp, channel, targetState);
      if (!success) {
        // Rollback
        updatedRelays[channel - 1] = currentState;
        _status = _status.copyWith(relays: updatedRelays);
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      updatedRelays[channel - 1] = currentState;
      _status = _status.copyWith(relays: updatedRelays);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleSwitch(int switchIdx) async {
    final currentState = _status.getSwitchState(switchIdx);
    final targetState = !currentState;

    // Optimistic UI update
    final updatedSwitches = List<bool>.from(_status.switches);
    if (switchIdx < updatedSwitches.length) {
      updatedSwitches[switchIdx] = targetState;
    }
    _status = _status.copyWith(switches: updatedSwitches);
    notifyListeners();

    try {
      final success = await _apiService.setSwitch(_espIp, switchIdx, targetState);
      if (!success) {
        updatedSwitches[switchIdx] = currentState;
        _status = _status.copyWith(switches: updatedSwitches);
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      updatedSwitches[switchIdx] = currentState;
      _status = _status.copyWith(switches: updatedSwitches);
      notifyListeners();
      return false;
    }
  }

  Future<bool> triggerServoTest() async {
    return _apiService.triggerServoTest(_espIp);
  }

  Future<bool> setServoConfig({
    required int restAngle,
    required int pressAngle,
    required int pressDurationMs,
  }) async {
    final success = await _apiService.setServoConfig(
      _espIp,
      restAngle: restAngle,
      pressAngle: pressAngle,
      pressDurationMs: pressDurationMs,
    );
    if (success) {
      _status = _status.copyWith(
        restAngle: restAngle,
        pressAngle: pressAngle,
        pressDurationMs: pressDurationMs,
      );
      notifyListeners();
    }
    return success;
  }

  Future<bool> addTimer({
    required int durationSec,
    required bool invertOnStartEnd,
    required String targetAction,
    required List<bool> targetRelays,
    required List<bool> targetSwitches,
  }) async {
    final success = await _apiService.addTimer(
      _espIp,
      durationSec: durationSec,
      invertOnStartEnd: invertOnStartEnd,
      targetAction: targetAction,
      targetRelays: targetRelays,
      targetSwitches: targetSwitches,
    );
    if (success) {
      await _silentRefresh();
    }
    return success;
  }

  Future<bool> controlTimer(int timerId, String command) async {
    final success = await _apiService.controlTimer(_espIp, timerId, command);
    if (success) {
      await _silentRefresh();
    }
    return success;
  }

  Future<bool> testConnection(String ipToTest) async {
    return _apiService.testConnection(ipToTest);
  }

  Future<bool> resetWifi() async {
    return _apiService.resetWifi(_espIp);
  }

  Future<void> setAutoRefresh(bool enabled) async {
    if (_autoRefresh == enabled) return;
    _autoRefresh = enabled;
    await _storageService.setAutoRefresh(enabled);

    if (_autoRefresh) {
      _startPolling();
    } else {
      _stopPolling();
    }
    notifyListeners();
  }

  Future<void> setPollInterval(int seconds) async {
    if (seconds < 1 || _pollInterval == seconds) return;
    _pollInterval = seconds;
    await _storageService.setPollInterval(seconds);

    if (_autoRefresh) {
      _stopPolling();
      _startPolling();
    }
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: _pollInterval), (_) {
      _silentRefresh();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _silentRefresh() async {
    try {
      final newStatus = await _apiService.getStatus(_espIp);
      _status = newStatus;
      _isConnected = true;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      if (_isConnected) {
        _isConnected = false;
        notifyListeners();
      }
    }
  }

  Future<bool> setDisplayPage(int page) async {
    final updatedPage = await _apiService.setDisplayPage(_espIp, page);
    if (updatedPage != null) {
      _status = _status.copyWith(displayPage: updatedPage);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> setRelayPolarity(bool activeLow) async {
    final success = await _apiService.setRelayPolarity(_espIp, activeLow);
    if (success) {
      _status = _status.copyWith(activeLow: activeLow);
      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
