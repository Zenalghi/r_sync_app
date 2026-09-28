// lib/providers/esp_provider.dart

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

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
  String? _relayPolarityError;

  EspProvider(this._apiService, this._storageService) {
    _espIp = _storageService.getEspIp();
    _autoRefresh = _storageService.getAutoRefresh();
    _pollInterval = _storageService.getPollInterval();

    // Defer initial cache loading and status fetch to after the widget tree completes its initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedCapabilities();
      refreshStatus();
      if (_autoRefresh) {
        _startPolling();
      }
    });
  }

  String get espIp => _espIp;
  EspStatus get status => _status;
  EspCapabilities get capabilities => _capabilities;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get autoRefresh => _autoRefresh;
  int get pollInterval => _pollInterval;
  String? get relayPolarityError => _relayPolarityError;
  bool get isServoBusy => _status.servoBusy;
  int get servoQueueLength => _status.servoQueueLength;
  List<int> get servoAngles => _status.servoAngles;
  bool get isOledConnected =>
      _isConnected && (_status.oledConnected || _capabilities.oledConnected);

  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  Future<void> _loadCachedCapabilities() async {
    final cached = await EspCapabilities.loadFromLocal();
    if (cached != null) {
      _capabilities = cached;
      _safeNotifyListeners();
    }
  }

  Future<void> setEspIp(String newIp) async {
    final cleanIp = newIp.trim();
    if (cleanIp.isEmpty || cleanIp == _espIp) return;

    _espIp = cleanIp;
    await _storageService.setEspIp(cleanIp);
    _safeNotifyListeners();

    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final newCaps = await _apiService.getCapabilities(_espIp);
      _capabilities = newCaps;

      final newStatus = await _apiService.getStatus(_espIp);
      _status = newStatus;
      _isConnected = true;
      _errorMessage = null;
    } catch (e) {
      _isConnected = false;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> toggleRelay(int channel) async {
    final currentState = _status.getRelayState(channel);
    final targetState = !currentState;

    final updatedRelays = List<bool>.from(_status.relays);
    if (channel - 1 < updatedRelays.length) {
      updatedRelays[channel - 1] = targetState;
    }
    _status = _status.copyWith(relays: updatedRelays);
    _safeNotifyListeners();

    try {
      final success = await _apiService.setRelay(_espIp, channel, targetState);
      if (!success) {
        updatedRelays[channel - 1] = currentState;
        _status = _status.copyWith(relays: updatedRelays);
        _safeNotifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      updatedRelays[channel - 1] = currentState;
      _status = _status.copyWith(relays: updatedRelays);
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> triggerSwitchAction(int switchIdx, bool turnOn) async {
    final updatedSwitches = List<bool>.from(_status.switches);
    if (switchIdx < updatedSwitches.length) {
      updatedSwitches[switchIdx] = turnOn;
    }
    _status = _status.copyWith(switches: updatedSwitches);
    _safeNotifyListeners();

    try {
      return await _apiService.setSwitch(_espIp, switchIdx, turnOn);
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleSwitch(int switchIdx) async {
    final currentState = _status.getSwitchState(switchIdx);
    return triggerSwitchAction(switchIdx, !currentState);
  }

  Future<bool> triggerServoTest({int? servoIdx}) async {
    return _apiService.triggerServoTest(_espIp, servoIdx: servoIdx);
  }

  Future<bool> setServoConfig({
    required int restAngle,
    required int pressAngle,
    required int pressDurationMs,
    List<int>? pressAngles,
  }) async {
    final success = await _apiService.setServoConfig(
      _espIp,
      restAngle: restAngle,
      pressAngle: pressAngle,
      pressDurationMs: pressDurationMs,
      pressAngles: pressAngles,
    );
    if (success) {
      _status = _status.copyWith(
        restAngle: restAngle,
        pressAngle: pressAngle,
        pressAngles: pressAngles,
        pressDurationMs: pressDurationMs,
      );
      _safeNotifyListeners();
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

  Future<bool> updateTimer({
    required int id,
    required int durationSec,
    required bool invertOnStartEnd,
    required String targetAction,
    required List<bool> targetRelays,
    required List<bool> targetSwitches,
  }) async {
    final success = await _apiService.updateTimer(
      _espIp,
      id: id,
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

  Future<bool> deleteTimer(int timerId) async {
    final success = await _apiService.deleteTimer(_espIp, timerId);
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

  /// Fetch hardware active config from ESP32
  Future<Map<String, List<bool>>?> fetchHardwareConfig() async {
    return _apiService.getHardwareConfig(_espIp);
  }

  /// Fetch relay polarity directly from ESP32
  Future<bool?> fetchRelayPolarity() async {
    return _apiService.getRelayPolarity(_espIp);
  }

  /// Set hardware active/inactive flags (relay/switch enable per-channel)
  Future<bool> setHardwareConfig({
    required List<bool> relays,
    required List<bool> switches,
  }) async {
    final success = await _apiService.setHardwareConfig(
      _espIp,
      relays: relays,
      switches: switches,
    );
    if (success) {
      _capabilities = EspCapabilities(
        deviceName: _capabilities.deviceName,
        version: _capabilities.version,
        relaysCount: relays.where((r) => r).length,
        switchesCount: switches.where((s) => s).length,
        servosCount: _capabilities.servosCount,
        timerFeature: _capabilities.timerFeature,
        maxTimers: _capabilities.maxTimers,
        schedulerFeature: _capabilities.schedulerFeature,
        maxSchedules: _capabilities.maxSchedules,
        servoConfigFeature: _capabilities.servoConfigFeature,
        oledConnected: _capabilities.oledConnected,
        activeRelays: relays,
        activeSwitches: switches,
      );
      await _capabilities.saveToLocal();
      _safeNotifyListeners();
      // Refresh to get updated status
      await _silentRefresh();
    }
    return success;
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
    _safeNotifyListeners();
  }

  Future<void> setPollInterval(int seconds) async {
    if (seconds < 1 || _pollInterval == seconds) return;
    _pollInterval = seconds;
    await _storageService.setPollInterval(seconds);

    if (_autoRefresh) {
      _stopPolling();
      _startPolling();
    }
    _safeNotifyListeners();
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
      _safeNotifyListeners();
    } catch (_) {
      if (_isConnected) {
        _isConnected = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<bool> setDisplayPage(int page) async {
    final updatedPage = await _apiService.setDisplayPage(_espIp, page);
    if (updatedPage != null) {
      _status = _status.copyWith(displayPage: updatedPage);
      _safeNotifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> setRelayPolarity(bool activeLow) async {
    final success = await _apiService.setRelayPolarity(_espIp, activeLow);
    if (success) {
      _relayPolarityError = null;
      _status = _status.copyWith(activeLow: activeLow);
      _safeNotifyListeners();
      await _silentRefresh();
    } else {
      _relayPolarityError = _apiService.relayPolarityError;
      _safeNotifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
