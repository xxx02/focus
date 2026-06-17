import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import '../models/browser_choice.dart';
import '../services/settings_store.dart';
import '../ui/webview_screen.dart';

/// Bir URL'i "app modunda" (sade, adres çubuğu/sekme olmadan) açar.
///
/// - Masaüstü (Win/Mac/Linux): seçili Chromium tarayıcıyı `--app=URL` ile başlatır.
/// - Android/iOS:
///   - Custom Tab modu: cihazın varsayılan tarayıcısında minimal görünüm.
///   - WebView modu: uygulama içi tam ekran (üst çubuk yok).
class BrowserLauncher {
  const BrowserLauncher();

  Future<void> launch(
    String url, {
    BrowserChoice? browser,
    BuildContext? context,
    AndroidOpenMode androidMode = AndroidOpenMode.customTab,
  }) async {
    final uri = Uri.parse(url);
    if (Platform.isAndroid || Platform.isIOS) {
      if (androidMode == AndroidOpenMode.webView &&
          context != null &&
          context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => WebViewScreen(url: url)),
        );
      } else {
        await _launchCustomTab(uri, context, browser);
      }
    } else {
      await _launchDesktop(url, browser);
    }
  }

  // --- Masaüstü: tarayıcıyı app modunda ayrı süreç olarak başlat ---
  Future<void> _launchDesktop(String url, BrowserChoice? browser) async {
    if (browser != null && browser.executablePath.isNotEmpty) {
      await Process.start(
        browser.executablePath,
        ['--app=$url'],
        mode: ProcessStartMode.detached,
      );
      return;
    }
    await ul.launchUrl(Uri.parse(url), mode: ul.LaunchMode.externalApplication);
  }

  // --- Mobil: Custom Tab (Android) / SafariVC (iOS) ---
  Future<void> _launchCustomTab(
    Uri uri,
    BuildContext? context,
    BrowserChoice? browser,
  ) async {
    final theme = context != null && context.mounted ? Theme.of(context) : null;
    // Belirli bir tarayıcı seçildiyse Chrome dışı tarayıcı için ipucu olarak ver.
    final fallback = browser?.kind.androidPackage;
    try {
      await launchUrl(
        uri,
        customTabsOptions: CustomTabsOptions(
          colorSchemes: theme == null
              ? null
              : CustomTabsColorSchemes.defaults(
                  toolbarColor: theme.colorScheme.surface,
                ),
          // Cihazın varsayılan tarayıcısını kullan (sadece Chrome'a kilitlenme).
          browser: CustomTabsBrowserConfiguration(
            prefersDefaultBrowser: true,
            fallbackCustomTabs: fallback == null ? null : [fallback],
          ),
          urlBarHidingEnabled: true,
          showTitle: false,
          shareState: CustomTabsShareState.off,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (_) {
      await ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
    }
  }
}
