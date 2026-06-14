import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bookmark.dart';

/// Yer imlerini yerel bir JSON dosyasında saklar ve reaktif olarak yayınlar.
class BookmarkStore extends ChangeNotifier {
  BookmarkStore();

  final List<Bookmark> _items = [];
  List<Bookmark> get items => List.unmodifiable(_items);

  File? _file;

  Future<File> _resolveFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    return _file = File('${dir.path}/bookmarks.json');
  }

  /// Diskten yükler. Uygulama başında bir kez çağrılır.
  Future<void> load() async {
    try {
      final file = await _resolveFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _items
          ..clear()
          ..addAll(Bookmark.decodeList(content));
      }
    } catch (_) {
      // Bozuk dosya: boş liste ile devam et.
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final file = await _resolveFile();
    await file.writeAsString(Bookmark.encodeList(_items));
  }

  Future<void> add(String title, String url) async {
    final cleanUrl = _normalizeUrl(url);
    final cleanTitle = title.trim().isEmpty ? cleanUrl : title.trim();
    _items.add(Bookmark(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: cleanTitle,
      url: cleanUrl,
    ));
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> update(String id, {String? title, String? url}) async {
    final i = _items.indexWhere((b) => b.id == id);
    if (i == -1) return;
    _items[i] = _items[i].copyWith(
      title: title,
      url: url == null ? null : _normalizeUrl(url),
    );
    notifyListeners();
    await _persist();
  }

  /// Tüm yer imlerini biçimli JSON metni olarak döndürür (export için).
  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(
        _items.map((b) => b.toJson()).toList(),
      );

  /// Verilen JSON metnini içe aktarır. [replace] true ise mevcutları siler,
  /// değilse URL bazında birleştirir (tekrarları atlar).
  Future<int> importJson(String source, {bool replace = false}) async {
    final incoming = Bookmark.decodeList(source);
    if (replace) {
      _items
        ..clear()
        ..addAll(incoming);
    } else {
      final existingUrls = _items.map((b) => b.url).toSet();
      for (final b in incoming) {
        if (!existingUrls.contains(b.url)) {
          _items.add(b);
          existingUrls.add(b.url);
        }
      }
    }
    notifyListeners();
    await _persist();
    return incoming.length;
  }

  String _normalizeUrl(String url) {
    final t = url.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }
}
