import 'dart:io';

import '../models/browser_choice.dart';

/// Sistemde kurulu Chromium tabanlı tarayıcıları (Brave/Chrome/Edge) bulur.
/// Android'de geçerli değildir (Custom Tab varsayılan tarayıcıyı kullanır).
class BrowserDetector {
  const BrowserDetector();

  Future<List<BrowserChoice>> detect() async {
    if (Platform.isAndroid || Platform.isIOS) return const [];
    if (Platform.isLinux) return _detectLinux();
    if (Platform.isMacOS) return _detectMacOs();
    if (Platform.isWindows) return _detectWindows();
    return const [];
  }

  // --- Linux: PATH'te bilinen komutları ara ---
  Future<List<BrowserChoice>> _detectLinux() async {
    const candidates = <BrowserKind, List<String>>{
      BrowserKind.brave: ['brave-browser', 'brave'],
      BrowserKind.chrome: ['google-chrome', 'google-chrome-stable'],
      BrowserKind.edge: ['microsoft-edge', 'microsoft-edge-stable'],
      BrowserKind.chromium: ['chromium', 'chromium-browser'],
    };
    final found = <BrowserChoice>[];
    for (final entry in candidates.entries) {
      for (final cmd in entry.value) {
        final path = await _which(cmd);
        if (path != null) {
          found.add(BrowserChoice(kind: entry.key, executablePath: path));
          break;
        }
      }
    }
    return found;
  }

  Future<String?> _which(String cmd) async {
    try {
      final result = await Process.run('which', [cmd]);
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim();
        if (out.isNotEmpty) return out.split('\n').first.trim();
      }
    } catch (_) {}
    return null;
  }

  // --- macOS: .app paketi içindeki binary'yi doğrudan kullan ---
  Future<List<BrowserChoice>> _detectMacOs() async {
    const candidates = <BrowserKind, String>{
      BrowserKind.brave:
          '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
      BrowserKind.chrome:
          '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      BrowserKind.edge:
          '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
      BrowserKind.chromium:
          '/Applications/Chromium.app/Contents/MacOS/Chromium',
    };
    final found = <BrowserChoice>[];
    for (final entry in candidates.entries) {
      if (await File(entry.value).exists()) {
        found.add(BrowserChoice(kind: entry.key, executablePath: entry.value));
      }
    }
    return found;
  }

  // --- Windows: tipik kurulum yollarını tara ---
  Future<List<BrowserChoice>> _detectWindows() async {
    final pf = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
    final pf86 = Platform.environment['ProgramFiles(x86)'] ??
        r'C:\Program Files (x86)';
    final local = Platform.environment['LOCALAPPDATA'] ?? '';

    final candidates = <BrowserKind, List<String>>{
      BrowserKind.brave: [
        '$pf\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
        '$pf86\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
        '$local\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
      ],
      BrowserKind.chrome: [
        '$pf\\Google\\Chrome\\Application\\chrome.exe',
        '$pf86\\Google\\Chrome\\Application\\chrome.exe',
        '$local\\Google\\Chrome\\Application\\chrome.exe',
      ],
      BrowserKind.edge: [
        '$pf\\Microsoft\\Edge\\Application\\msedge.exe',
        '$pf86\\Microsoft\\Edge\\Application\\msedge.exe',
      ],
    };

    final found = <BrowserChoice>[];
    for (final entry in candidates.entries) {
      for (final path in entry.value) {
        if (await File(path).exists()) {
          found.add(BrowserChoice(kind: entry.key, executablePath: path));
          break;
        }
      }
    }
    return found;
  }
}
