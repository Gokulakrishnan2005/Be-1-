import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'journal_editor_screen.dart';
import 'journal_viewer_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final entries = storage.getJournalEntries()
      ..sort((a, b) => b.date.compareTo(a.date));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Journal'),
        previousPageTitle: 'Profile',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const JournalEditorScreen()),
          ),
        ),
      ),
      child: SafeArea(
        child: entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.book,
                        size: 64, color: AppTheme.systemGray.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('No entries yet',
                        style: TextStyle(
                            color: AppTheme.systemGray, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Tap + to write your first entry',
                        style: TextStyle(
                            color: AppTheme.systemGray, fontSize: 14)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final preview = entry.contentBlocks
                      .where((b) => b.type != 'image')
                      .map((b) => b.content)
                      .take(2)
                      .join(' ')
                      .replaceAll('\n', ' ');
                  final previewText = preview.length > 80
                      ? '${preview.substring(0, 80)}...'
                      : preview;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (_) => JournalViewerScreen(entry: entry)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.pureCeramicWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.systemBlack)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                  DateFormat('MMMM d, yyyy').format(entry.date),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.systemGray)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: entry.mood == 'positive'
                                      ? const Color(0xFF34C759)
                                          .withOpacity(0.12)
                                      : const Color(0xFFFF3B30)
                                          .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  entry.mood == 'positive'
                                      ? '☀️ Positive'
                                      : '🌧️ Negative',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: entry.mood == 'positive'
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFFFF3B30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (previewText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(previewText,
                                style: const TextStyle(
                                    fontSize: 14, color: AppTheme.systemGray),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
