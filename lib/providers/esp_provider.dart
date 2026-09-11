import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/esp_status.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Provider for managing ESP32 connection state, dynamic IP,
/// background polling, and real-time relay control.
/// Includes race-condition guards to prevent stale polling from reverting manual toggles.
class EspProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  late String _espIp;
  EspStatus _status = EspStatus.initial();
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;
  late bool _autoRefresh;
  late int _pollInterval;

  // Race condition guards for manual toggling
  bool _isTogglingRelay1 = false;
  bool _isTogglingRelay2 = false;
  DateTime? _lastToggleTimeRelay1;
  DateTime? _lastToggleTimeRelay2;

  // Guard window: background polling will not overwrite a relay state
  // if it was toggled within this duration (in milliseconds).
  static const int _toggleProtectionWindowMs = 2500;

  EspProvider(this._apiService, this._storageService) {
    _espIp = _storageService.getEspIp();
    _autoRefresh = _storageService.getAutoRefresh();
    _pollInterval = _storageService.getPollInterval();

    // Initial fetch & start timer if enabled
    refreshStatus();
    if (_autoRefresh) {
      _startPolling();
    }
  }

  String get espIp => _espIp;
  EspStatus get status => _status;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get autoRefresh => _autoRefresh;
  int get pollInterval => _pollInterval;

  /// Update ESP32 IP address and trigger status refresh
  Future<void> setEspIp(String newIp) async {
    final cleanIp = newIp.trim();
    if (cleanIp.isEmpty || cleanIp == _espIp) return;

    _espIp = cleanIp;
    await _storageService.setEspIp(cleanIp);
    notifyListeners();

    await refreshStatus();
  }

  /// Refreshes system status from ESP32 with toggle protection
  Future<void> refreshStatus() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newStatus = await _apiService.getStatus(_espIp);
      _status = _mergeStatusSafely(newStatus);
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

  /// Optimistic toggle of relay state (channel 1 or 2) with race-condition prevention
  Future<bool> toggleRelay(int channel) async {
    // Prevent double-tapping while the same channel is in-flight
    if (channel == 1 && _isTogglingRelay1) return false;
    if (channel == 2 && _isTogglingRelay2) return false;

    final currentRelayState = channel == 1 ? _status.relay1 : _status.relay2;
    final targetState = !currentRelayState;

    // 1. Mark toggling active and record timestamp
    if (channel == 1) {
      _isTogglingRelay1 = true;
      _lastToggleTimeRelay1 = DateTime.now();
    } else {
      _isTogglingRelay2 = true;
      _lastToggleTimeRelay2 = DateTime.now();
    }

    // 2. Optimistic UI update immediately
    if (channel == 1) {
      _status = _status.copyWith(relay1: targetState);
    } else {
      _status = _status.copyWith(relay2: targetState);
    }
    notifyListeners();

    // 3. Reset background polling countdown so it won't fire during user interaction
    if (_autoRefresh) {
      _startPolling();
    }

    // 4. Call ESP32 API
    try {
      final success = await _apiService.setRelay(_espIp, channel, targetState);
      if (!success) {
        // Rollback on server rejection
        _rollbackRelay(channel, currentRelayState);
        return false;
      }

      // Update timestamp to extend protection window after network round-trip
      if (channel == 1) {
        _lastToggleTimeRelay1 = DateTime.now();
      } else {
        _lastToggleTimeRelay2 = DateTime.now();
      }
      return true;
    } catch (e) {
      // Rollback on network exception
      _rollbackRelay(channel, currentRelayState);
      _errorMessage = 'Gagal mengubah status Relay $channel: $e';
      notifyListeners();
      return false;
    } finally {
      if (channel == 1) {
        _isTogglingRelay1 = false;
      } else {
        _isTogglingRelay2 = false;
      }
    }
  }

  void _rollbackRelay(int channel, bool previousState) {
    if (channel == 1) {
      _status = _status.copyWith(relay1: previousState);
    } else {
      _status = _status.copyWith(relay2: previousState);
    }
    notifyListeners();
  }

  /// Sets state directly
  Future<bool> setRelayState(int channel, bool state) async {
    final currentRelayState = channel == 1 ? _status.relay1 : _status.relay2;
    if (currentRelayState == state) return true;
    return toggleRelay(channel);
  }

  /// Tests connectivity to a given IP
  Future<bool> testConnection(String ipToTest) async {
    return _apiService.testConnection(ipToTest);
  }

  /// Configures auto-refresh polling
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

  /// Configures polling interval in seconds
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

  /// Background polling without setting _isLoading (avoids UI flashing)
  Future<void> _silentRefresh() async {
    try {
      final newStatus = await _apiService.getStatus(_espIp);
      _status = _mergeStatusSafely(newStatus);
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

  bool _isSwitchingDisplay = false;
  bool get isSwitchingDisplay => _isSwitchingDisplay;

  /// Toggles OLED display between Page 0 (Status) and Page 1 (Scheduler)
  Future<bool> toggleDisplayPage() async {
    final nextPage = (_status.displayPage + 1) % 2;
    return setDisplayPage(nextPage);
  }

  /// Sets specific OLED display page (0 = Status & Time, 1 = Scheduler)
  Future<bool> setDisplayPage(int page) async {
    if (_isSwitchingDisplay) return false;
    _isSwitchingDisplay = true;

    final previousPage = _status.displayPage;
    // Optimistic UI update
    _status = _status.copyWith(displayPage: page);
    notifyListeners();

    try {
      final updatedPage = await _apiService.setDisplayPage(_espIp, page);
      if (updatedPage == null) {
        _status = _status.copyWith(displayPage: previousPage);
        notifyListeners();
        return false;
      }
      _status = _status.copyWith(displayPage: updatedPage);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error changing OLED display page: $e');
      _status = _status.copyWith(displayPage: previousPage);
      notifyListeners();
      return false;
    } finally {
      _isSwitchingDisplay = false;
      notifyListeners();
    }
  }

  /// Merges new ESP32 status while protecting recently manually toggled relay states
  /// from being overwritten by delayed/stale in-flight polling responses.
  EspStatus _mergeStatusSafely(EspStatus incoming) {
    final now = DateTime.now();

    final preserveRelay1 = _isTogglingRelay1 ||
        (_lastToggleTimeRelay1 != null &&
            now.difference(_lastToggleTimeRelay1!).inMilliseconds <
                _toggleProtectionWindowMs);

    final preserveRelay2 = _isTogglingRelay2 ||
        (_lastToggleTimeRelay2 != null &&
            now.difference(_lastToggleTimeRelay2!).inMilliseconds <
                _toggleProtectionWindowMs);

    final preserveDisplay = _isSwitchingDisplay;

    return incoming.copyWith(
      relay1: preserveRelay1 ? _status.relay1 : incoming.relay1,
      relay2: preserveRelay2 ? _status.relay2 : incoming.relay2,
      displayPage: preserveDisplay ? _status.displayPage : incoming.displayPage,
    );
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
