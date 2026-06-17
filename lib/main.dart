import 'package:flutter/material.dart';

import 'services/bookmark_store.dart';
import 'services/browser_detector.dart';
import 'services/browser_launcher.dart';
import 'services/query_resolver.dart';
import 'services/settings_store.dart';
import 'services/window_service.dart';
import 'theme/app_theme.dart';
import 'ui/app_scope.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bookmarks = BookmarkStore();
  final settings = SettingsStore();
  const detector = BrowserDetector();

  await Future.wait([bookmarks.load(), settings.load()]);
  final browsers = await detector.detect();
  settings.reconcileBrowsers(browsers);

  // Masaüstünde widget davranışını (kısayol/tepsi/oto-başlat/pencere) hazırla.
  final windowService = WindowService();
  await windowService.init(
    hotkeyEnabled: settings.globalHotkey,
    autoStartEnabled: settings.autoStart,
  );

  runApp(FocusApp(
    bookmarks: bookmarks,
    settings: settings,
    browsers: browsers,
    windowService: windowService,
  ));
}

class FocusApp extends StatelessWidget {
  const FocusApp({
    super.key,
    required this.bookmarks,
    required this.settings,
    required this.browsers,
    required this.windowService,
  });

  final BookmarkStore bookmarks;
  final SettingsStore settings;
  final List<dynamic> browsers;
  final WindowService windowService;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      bookmarks: bookmarks,
      settings: settings,
      browsers: browsers.cast(),
      launcher: const BrowserLauncher(),
      resolver: const QueryResolver(),
      windowService: windowService,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'Focus',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
