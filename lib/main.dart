import 'package:flutter/material.dart';

import 'services/bookmark_store.dart';
import 'services/browser_detector.dart';
import 'services/browser_launcher.dart';
import 'services/query_resolver.dart';
import 'services/settings_store.dart';
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

  runApp(FocusApp(
    bookmarks: bookmarks,
    settings: settings,
    browsers: browsers,
  ));
}

class FocusApp extends StatelessWidget {
  const FocusApp({
    super.key,
    required this.bookmarks,
    required this.settings,
    required this.browsers,
  });

  final BookmarkStore bookmarks;
  final SettingsStore settings;
  final List<dynamic> browsers;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      bookmarks: bookmarks,
      settings: settings,
      browsers: browsers.cast(),
      launcher: const BrowserLauncher(),
      resolver: const QueryResolver(),
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
