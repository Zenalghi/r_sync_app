import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Provider for managing application theme mode (Light, Dark, System)
/// with persistence via SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  late ThemeMode _themeMode;

  ThemeProvider(this._storageService) {
    _themeMode = _storageService.getThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // For system, check platform dispatcher in UI
    return false;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storageService.setThemeMode(mode);
  }
}
