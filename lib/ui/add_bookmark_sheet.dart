import 'package:flutter/material.dart';

import '../models/bookmark.dart';

/// Yer imi ekleme/düzenleme formu. Kaydedilirse (title, url) döndürür.
class AddBookmarkSheet extends StatefulWidget {
  const AddBookmarkSheet({super.key, this.existing});

  final Bookmark? existing;

  static Future<({String title, String url})?> show(
    BuildContext context, {
    Bookmark? existing,
  }) {
    return showModalBottomSheet<({String title, String url})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBookmarkSheet(existing: existing),
    );
  }

  @override
  State<AddBookmarkSheet> createState() => _AddBookmarkSheetState();
}

class _AddBookmarkSheetState extends State<AddBookmarkSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _url =
      TextEditingController(text: widget.existing?.url ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (title: _title.text.trim(), url: _url.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Yer imini düzenle' : 'Yer imi ekle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _url,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Adres (URL)',
                hintText: 'github.com',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Adres gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Başlık (opsiyonel)',
                hintText: 'GitHub',
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
