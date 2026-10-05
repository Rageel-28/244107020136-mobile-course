import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local_note_repository.dart';
import 'data/preferences_service.dart';
import 'providers/providers.dart';
import 'ui/app_theme.dart';
import 'ui/notes_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await PreferencesService.create();
  // Persist this launch time before showing the UI; the UI reads it back
  // through `lastOpenedProvider`.
  final openedAt = DateTime.now();
  await prefs.setLastOpened(openedAt);

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        noteRepositoryProvider.overrideWithValue(LocalNoteRepository()),
      ],
      child: const OfflineNotesApp(),
    ),
  );
}

class OfflineNotesApp extends ConsumerWidget {
  const OfflineNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Offline Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const NotesListPage(),
    );
  }
}
