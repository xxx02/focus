import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import '../models/browser_choice.dart';

/// Bir URL'i "app modunda" (sade, adres çubuğu/sekme olmadan) açar.
///
/// - Masaüstü (Win/Mac/Linux): seçili Chromium tarayıcıyı `--app=URL` ile başlatır.
/// - Android/iOS: Custom Tab / SFSafariViewController ile minimal görünüm açar.
class BrowserLauncher {
  const BrowserLauncher();

  /// [browser] yalnızca masaüstünde kullanılır; mobilde null olabilir.
  Future<void> launch(
    String url, {
    BrowserChoice? browser,
    BuildContext? context,
  }) async {
    final uri = Uri.parse(url);
    if (Platform.isAndroid || Platform.isIOS) {
      await _launchMobile(uri, context);
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
    // Tarayıcı seçilmemişse normal şekilde varsayılan tarayıcıda aç.
    await ul.launchUrl(Uri.parse(url), mode: ul.LaunchMode.externalApplication);
  }

  // --- Mobil: Custom Tab (Android) / SafariVC (iOS) ---
  Future<void> _launchMobile(Uri uri, BuildContext? context) async {
    final theme = context != null ? Theme.of(context) : null;
    try {
      await launchUrl(
        uri,
        customTabsOptions: CustomTabsOptions(
          colorSchemes: theme == null
              ? null
              : CustomTabsColorSchemes.defaults(
                  toolbarColor: theme.colorScheme.surface,
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
