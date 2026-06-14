/// Arama çubuğuna girilen metni URL veya Google araması olarak çözer.
class QueryResolver {
  const QueryResolver();

  /// Girilen [input]'tan açılacak nihai URL'i üretir.
  String resolve(String input) {
    final text = input.trim();
    if (text.isEmpty) return 'https://www.google.com';

    if (_looksLikeUrl(text)) {
      if (text.startsWith('http://') || text.startsWith('https://')) {
        return text;
      }
      return 'https://$text';
    }
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(text)}';
  }

  /// Boşluk içermeyen ve nokta içeren (ya da şema ile başlayan) ifadeyi
  /// URL kabul eder. "localhost" ve "host:port" da URL sayılır.
  bool _looksLikeUrl(String text) {
    if (text.contains(' ')) return false;
    if (text.startsWith('http://') || text.startsWith('https://')) return true;
    if (text.startsWith('localhost')) return true;
    if (!text.contains('.')) return false;
    // En az bir noktadan sonra harf/rakam olan basit alan adı kontrolü.
    final domain = text.split('/').first;
    return RegExp(r'^[\w-]+(\.[\w-]+)+(:\d+)?$').hasMatch(domain);
  }
}
