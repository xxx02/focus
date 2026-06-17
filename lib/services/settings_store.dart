import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/browser_choice.dart';

/// Android'de bir sayfanın nasıl açılacağı.
enum AndroidOpenMode {
  /// Chrome Custom Tab (cihazın varsayılan tarayıcısını kullanır).
  customTab,

  /// Uygulama içi tam ekran WebView (üst çubuk yok).
  webView,
}

/// Kullanıcı tercihlerini (seçili tarayıcı, tema, widget davranışı) saklar.
class SettingsStore extends ChangeNotifier {
  SettingsStore();

  static const _kBrowser = 'selected_browser';
  static const _kThemeMode = 'theme_mode';
  static const _kAndroidOpenMode = 'android_open_mode';
  static const _kAutoStart = 'auto_start';
  static const _kGlobalHotkey = 'global_hotkey';

  SharedPreferences? _prefs;

  BrowserChoice? _selectedBrowser;
  BrowserChoice? get selectedBrowser => _selectedBrowser;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AndroidOpenMode _androidOpenMode = AndroidOpenMode.customTab;
  AndroidOpenMode get androidOpenMode => _androidOpenMode;

  bool _autoStart = false;
  bool get autoStart => _autoStart;

  bool _globalHotkey = true;
  bool get globalHotkey => _globalHotkey;

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

    _androidOpenMode = _prefs!.getString(_kAndroidOpenMode) == 'webView'
        ? AndroidOpenMode.webView
        : AndroidOpenMode.customTab;
    _autoStart = _prefs!.getBool(_kAutoStart) ?? false;
    _globalHotkey = _prefs!.getBool(_kGlobalHotkey) ?? true;

    notifyListeners();
  }

  Future<void> setAndroidOpenMode(AndroidOpenMode mode) async {
    _androidOpenMode = mode;
    notifyListeners();
    await _prefs?.setString(_kAndroidOpenMode, mode.name);
  }

  Future<void> setAutoStart(bool value) async {
    _autoStart = value;
    notifyListeners();
    await _prefs?.setBool(_kAutoStart, value);
  }

  Future<void> setGlobalHotkey(bool value) async {
    _globalHotkey = value;
    notifyListeners();
    await _prefs?.setBool(_kGlobalHotkey, value);
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
