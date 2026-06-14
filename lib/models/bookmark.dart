import 'dart:convert';

/// Tek bir yer imi. Hafif, JSON ile serileştirilebilir.
class Bookmark {
  Bookmark({
    required this.id,
    required this.title,
    required this.url,
  });

  final String id;
  final String title;
  final String url;

  /// Yer iminin host'una göre Google favicon servisinden ikon URL'i.
  String get faviconUrl {
    final host = Uri.tryParse(url)?.host ?? '';
    return 'https://www.google.com/s2/favicons?domain=$host&sz=64';
  }

  Bookmark copyWith({String? title, String? url}) => Bookmark(
        id: id,
        title: title ?? this.title,
        url: url ?? this.url,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        title: (json['title'] as String?)?.trim().isNotEmpty == true
            ? json['title'] as String
            : (json['url'] as String),
        url: json['url'] as String,
      );

  static String encodeList(List<Bookmark> items) =>
      jsonEncode(items.map((b) => b.toJson()).toList());

  static List<Bookmark> decodeList(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Bookmark.fromJson)
        .toList();
  }
}
