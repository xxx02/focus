import 'package:flutter/material.dart';

import '../models/bookmark.dart';
import 'add_bookmark_sheet.dart';
import 'app_scope.dart';
import 'bookmark_tile.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final scope = AppScope.of(context);
    if (!_canLaunchDesktop(scope)) return;
    await scope.launcher.launch(
      url,
      browser: scope.settings.selectedBrowser,
      context: context,
    );
  }

  /// Masaüstünde tarayıcı seçili değilse uyar.
  bool _canLaunchDesktop(AppScope scope) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows;
    if (isDesktop && scope.browsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Brave/Chrome/Edge bulunamadı. Lütfen birini kurun.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  void _submitSearch() {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    final url = AppScope.of(context).resolver.resolve(text);
    _openUrl(url);
  }

  Future<void> _addBookmark() async {
    final result = await AddBookmarkSheet.show(context);
    if (result == null || !mounted) return;
    await AppScope.of(context).bookmarks.add(result.title, result.url);
  }

  Future<void> _editBookmark(Bookmark bookmark) async {
    final result = await AddBookmarkSheet.show(context, existing: bookmark);
    if (result == null || !mounted) return;
    await AppScope.of(context)
        .bookmarks
        .update(bookmark.id, title: result.title, url: result.url);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBookmark,
        icon: const Icon(Icons.add),
        label: const Text('Yer imi'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _SearchBar(
                controller: _searchController,
                onSubmit: _submitSearch,
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: scope.bookmarks,
                builder: (context, _) {
                  final items = scope.bookmarks.items;
                  if (items.isEmpty) return const _EmptyState();
                  return _BookmarkGrid(
                    items: items,
                    onOpen: (b) => _openUrl(b.url),
                    onDelete: (b) => scope.bookmarks.remove(b.id),
                    onEdit: _editBookmark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Google\'da ara veya adres gir',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: onSubmit,
        ),
      ),
    );
  }
}

class _BookmarkGrid extends StatelessWidget {
  const _BookmarkGrid({
    required this.items,
    required this.onOpen,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Bookmark> items;
  final void Function(Bookmark) onOpen;
  final void Function(Bookmark) onDelete;
  final void Function(Bookmark) onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Küçük ekranda az, geniş ekranda çok sütun (responsive).
        final crossAxisCount = (constraints.maxWidth / 130).floor().clamp(2, 8);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final b = items[i];
            return BookmarkTile(
              bookmark: b,
              onOpen: () => onOpen(b),
              onDelete: () => onDelete(b),
              onEdit: () => onEdit(b),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'Henüz yer imi yok',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Sağ alttaki "Yer imi" ile ekleyin',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
