import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Masaüstünde (Win/Mac/Linux) uygulamayı bir "widget" gibi davrandırır:
/// - Ctrl+Space global kısayolu ile ön plana getir/gizle
/// - Sistem tepsisi simgesi + menü
/// - Kapatma (X) tuşunda çıkmak yerine tepsiye küçül
/// - OS açılışında başlatma (oto-başlat)
/// - Pencereyi varsayılan boyut/konuma sıfırlama
///
/// Mobilde tüm metotlar sessizce no-op'tur.
class WindowService with WindowListener, TrayListener {
  WindowService();

  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Standart (varsayılan) pencere boyutu.
  static const Size defaultSize = Size(440, 640);

  bool _trayReady = false;

  /// Uygulama başında, runApp'ten ÖNCE çağrılır.
  Future<void> init({
    required bool hotkeyEnabled,
    required bool autoStartEnabled,
  }) async {
    if (!isDesktop) return;

    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    const options = WindowOptions(
      size: defaultSize,
      center: true,
      title: 'Focus',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // X tuşu uygulamayı kapatmasın; onWindowClose'da tepsiye küçültürüz.
    await windowManager.setPreventClose(true);

    await _initTray();
    await _setupAutostartPlugin();

    await setHotkeyEnabled(hotkeyEnabled);
    await setAutoStart(autoStartEnabled);
  }

  // ---------------------------------------------------------------- tray
  Future<void> _initTray() async {
    try {
      await trayManager.setIcon(
        Platform.isWindows ? 'assets/tray/tray.ico' : 'assets/tray/tray.png',
      );
      await trayManager.setToolTip('Focus');
      await _refreshTrayMenu();
      trayManager.addListener(this);
      _trayReady = true;
    } catch (_) {
      // Tepsi başlatılamazsa uygulama yine de çalışır.
      _trayReady = false;
    }
  }

  Future<void> _refreshTrayMenu() async {
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Göster / Gizle'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Çıkış'),
    ]));
  }

  // ------------------------------------------------------------ visibility
  Future<void> showWindow() async {
    if (!isDesktop) return;
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> toggleWindow() async {
    if (!isDesktop) return;
    final visible = await windowManager.isVisible();
    final focused = await windowManager.isFocused();
    if (visible && focused) {
      await windowManager.hide();
    } else {
      await showWindow();
    }
  }

  /// Pencereyi varsayılan boyut + ekran ortasına döndürür.
  Future<void> resetWindow() async {
    if (!isDesktop) return;
    await windowManager.setSize(defaultSize);
    await windowManager.center();
    await showWindow();
  }

  // -------------------------------------------------------------- hotkey
  Future<void> setHotkeyEnabled(bool enabled) async {
    if (!isDesktop) return;
    await hotKeyManager.unregisterAll();
    if (!enabled) return;
    final hotKey = HotKey(
      key: LogicalKeyboardKey.space,
      modifiers: [HotKeyModifier.control],
      scope: HotKeyScope.system,
    );
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) => toggleWindow(),
    );
  }

  // ------------------------------------------------------------ autostart
  Future<void> _setupAutostartPlugin() async {
    try {
      final info = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: 'Focus',
        appPath: Platform.resolvedExecutable,
        packageName: info.packageName,
      );
    } catch (_) {}
  }

  Future<void> setAutoStart(bool enabled) async {
    if (!isDesktop) return;
    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (_) {}
  }

  Future<bool> isAutoStartEnabled() async {
    if (!isDesktop) return false;
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Tepsiye küçültme yerine gerçekten çıkış yapar.
  Future<void> quit() async {
    if (!isDesktop) return;
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  // ---------------------------------------------------------- listeners
  @override
  void onWindowClose() async {
    // X'e basıldığında çıkma; tepsiye küçül.
    if (await windowManager.isPreventClose()) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() => toggleWindow();

  @override
  void onTrayIconRightMouseDown() {
    if (_trayReady) trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        toggleWindow();
        break;
      case 'exit':
        quit();
        break;
    }
  }
}
