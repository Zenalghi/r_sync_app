import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistent local storage using SharedPreferences.
class StorageService {
  static const String _keyEspIp = 'r_sync_esp_ip';
  static const String _keyThemeMode = 'r_sync_theme_mode';
  static const String _keyAutoRefresh = 'r_sync_auto_refresh';
  static const String _keyPollInterval = 'r_sync_poll_interval';

  static const String defaultEspIp = '192.168.4.1';
  static const int defaultPollInterval = 3; // seconds

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- ESP IP Address ---
  String getEspIp() {
    return _prefs.getString(_keyEspIp) ?? defaultEspIp;
  }

  Future<bool> setEspIp(String ip) {
    return _prefs.setString(_keyEspIp, ip.trim());
  }

  // --- Theme Mode ---
  ThemeMode getThemeMode() {
    final modeStr = _prefs.getString(_keyThemeMode);
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    return _prefs.setString(_keyThemeMode, val);
  }

  // --- Auto Refresh ---
  bool getAutoRefresh() {
    return _prefs.getBool(_keyAutoRefresh) ?? true;
  }

  Future<bool> setAutoRefresh(bool enabled) {
    return _prefs.setBool(_keyAutoRefresh, enabled);
  }

  // --- Polling Interval ---
  int getPollInterval() {
    return _prefs.getInt(_keyPollInterval) ?? defaultPollInterval;
  }

  Future<bool> setPollInterval(int seconds) {
    return _prefs.setInt(_keyPollInterval, seconds);
  }
}
