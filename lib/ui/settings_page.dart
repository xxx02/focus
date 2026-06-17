import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: AnimatedBuilder(
        animation: scope.settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionTitle('Tarayıcı'),
              if (scope.browsers.isEmpty)
                const ListTile(
                  leading: Icon(Icons.warning_amber_rounded),
                  title: Text('Tarayıcı bulunamadı'),
                  subtitle: Text(
                    'Brave, Chrome veya Edge kurulu değil. '
                    'Sayfalar varsayılan tarayıcıda açılır.',
                  ),
                )
              else
                RadioGroup<String>(
                  groupValue: scope.settings.selectedBrowser?.id,
                  onChanged: (id) {
                    for (final b in scope.browsers) {
                      if (b.id == id) {
                        scope.settings.setBrowser(b);
                        break;
                      }
                    }
                  },
                  child: Column(
                    children: [
                      for (final b in scope.browsers)
                        RadioListTile<String>(
                          value: b.id,
                          title: Text(b.label),
                          subtitle: Text(
                            b.executablePath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: const Icon(Icons.public),
                        ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              const _SectionTitle('Görünüm'),
              RadioGroup<ThemeMode>(
                groupValue: scope.settings.themeMode,
                onChanged: (m) {
                  if (m != null) scope.settings.setThemeMode(m);
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('Sistem'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('Açık'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('Koyu'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              const _SectionTitle('Yer imleri'),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Dışa aktar'),
                subtitle: const Text('Yer imlerini JSON olarak kaydet/paylaş'),
                onTap: () => _export(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('İçe aktar'),
                subtitle: const Text('JSON dosyasından yer imlerini ekle'),
                onTap: () => _import(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final json = scope.bookmarks.exportJson();

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobil: geçici dosyaya yazıp paylaşım sayfasını aç.
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/focus_bookmarks_export.json');
        await file.writeAsString(json);
        await Share.shareXFiles([XFile(file.path)], text: 'Focus yer imleri');
      } else {
        // Masaüstü: kullanıcıya yer sor, ardından dosyayı SEÇİLEN yola yaz.
        // (saveFile masaüstünde yalnızca yolu döndürür; dosyayı biz yazarız.)
        final savePath = await FilePicker.saveFile(
          dialogTitle: 'Yer imlerini kaydet',
          fileName: 'focus_bookmarks_export.json',
        );
        if (savePath == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Dışa aktarma iptal edildi')),
          );
          return;
        }
        final path =
            savePath.toLowerCase().endsWith('.json') ? savePath : '$savePath.json';
        await File(path).writeAsString(json);
        messenger.showSnackBar(
          SnackBar(content: Text('Kaydedildi: $path')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Dışa aktarma başarısız: $e')),
      );
    }
  }

  Future<void> _import(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final content = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();

      final count = await scope.bookmarks.importJson(content);
      messenger.showSnackBar(
        SnackBar(content: Text('$count yer imi işlendi')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('İçe aktarma başarısız: $e')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
