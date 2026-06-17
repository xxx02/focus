import 'package:flutter/widgets.dart';

import '../models/browser_choice.dart';
import '../services/bookmark_store.dart';
import '../services/browser_launcher.dart';
import '../services/query_resolver.dart';
import '../services/settings_store.dart';
import '../services/window_service.dart';

/// Servisleri widget ağacına taşıyan basit bağımlılık kapsayıcısı.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.bookmarks,
    required this.settings,
    required this.browsers,
    required this.launcher,
    required this.resolver,
    required this.windowService,
    required super.child,
  });

  final BookmarkStore bookmarks;
  final SettingsStore settings;
  final List<BrowserChoice> browsers;
  final BrowserLauncher launcher;
  final QueryResolver resolver;
  final WindowService windowService;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      bookmarks != oldWidget.bookmarks ||
      settings != oldWidget.settings ||
      browsers != oldWidget.browsers;
}
