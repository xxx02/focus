/// Algılanan bir tarayıcının türü.
enum BrowserKind { brave, chrome, edge, chromium }

extension BrowserKindX on BrowserKind {
  String get label => switch (this) {
        BrowserKind.brave => 'Brave',
        BrowserKind.chrome => 'Google Chrome',
        BrowserKind.edge => 'Microsoft Edge',
        BrowserKind.chromium => 'Chromium',
      };

  /// Android paket adı (Custom Tab tarayıcı ipucu için).
  String? get androidPackage => switch (this) {
        BrowserKind.brave => 'com.brave.browser',
        BrowserKind.chrome => 'com.android.chrome',
        BrowserKind.edge => 'com.microsoft.emmx',
        BrowserKind.chromium => null,
      };
}

/// Sistemde bulunmuş, app modunda başlatılabilen bir tarayıcı.
class BrowserChoice {
  const BrowserChoice({
    required this.kind,
    required this.executablePath,
  });

  final BrowserKind kind;

  /// Çalıştırılabilir dosyanın tam yolu (masaüstü). Android'de boş.
  final String executablePath;

  String get label => kind.label;

  /// Ayarlarda saklamak için kararlı kimlik.
  String get id => '${kind.name}:$executablePath';

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'executablePath': executablePath,
      };

  factory BrowserChoice.fromJson(Map<String, dynamic> json) => BrowserChoice(
        kind: BrowserKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => BrowserKind.chrome,
        ),
        executablePath: json['executablePath'] as String? ?? '',
      );
}
