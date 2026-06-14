import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/browser_choice.dart';

/// Kullanıcı tercihlerini (seçili tarayıcı, tema) saklar.
class SettingsStore extends ChangeNotifier {
  SettingsStore();

  static const _kBrowser = 'selected_browser';
  static const _kThemeMode = 'theme_mode';

  SharedPreferences? _prefs;

  BrowserChoice? _selectedBrowser;
  BrowserChoice? get selectedBrowser => _selectedBrowser;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final browserJson = _prefs!.getString(_kBrowser);
    if (browserJson != null) {
      try {
        _selectedBrowser =
            BrowserChoice.fromJson(jsonDecode(browserJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    final mode = _prefs!.getString(_kThemeMode);
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    notifyListeners();
  }

  /// Algılanan listeden seçili tarayıcıyı doğrular; geçersizse ilkini seçer.
  void reconcileBrowsers(List<BrowserChoice> available) {
    if (available.isEmpty) {
      _selectedBrowser = null;
      notifyListeners();
      return;
    }
    final stillValid = _selectedBrowser != null &&
        available.any((b) => b.id == _selectedBrowser!.id);
    if (!stillValid) {
      _selectedBrowser = available.first;
      _prefs?.setString(_kBrowser, jsonEncode(_selectedBrowser!.toJson()));
    }
    notifyListeners();
  }

  Future<void> setBrowser(BrowserChoice browser) async {
    _selectedBrowser = browser;
    notifyListeners();
    await _prefs?.setString(_kBrowser, jsonEncode(browser.toJson()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs?.setString(_kThemeMode, value);
  }
}
