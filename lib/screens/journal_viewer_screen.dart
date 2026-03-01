import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'journal_editor_screen.dart';

class JournalViewerScreen extends StatelessWidget {
  final JournalEntry entry;
  const JournalViewerScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.pureCeramicWhite,
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Journal',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: () => Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                    builder: (_) => JournalEditorScreen(existingEntry: entry)),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.trash,
                  color: CupertinoColors.systemRed),
              onPressed: () async {
                final confirm = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Delete Entry?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(ctx, false)),
                      CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Delete'),
                          onPressed: () => Navigator.pop(ctx, true)),
                    ],
                  ),
                );
                if (confirm == true) {
                  final storage = context.read<StorageService>();
                  await storage.deleteJournalEntry(entry.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.systemBlack,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.systemGray)),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.mood == 'positive'
                          ? const Color(0xFF34C759).withOpacity(0.12)
                          : const Color(0xFFFF3B30).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.mood == 'positive' ? '☀️ Positive' : '🌧️ Negative',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: entry.mood == 'positive'
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...entry.contentBlocks.map((block) {
                switch (block.type) {
                  case 'heading':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(block.content,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.systemBlack,
                          )),
                    );
                  case 'subheading':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(block.content,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.systemBlack,
                          )),
                    );
                  case 'image':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(block.content),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: AppTheme.systemGray6,
                            child: const Center(
                                child: Text('Image not found',
                                    style:
                                        TextStyle(color: AppTheme.systemGray))),
                          ),
                        ),
                      ),
                    );
                  default: // paragraph
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(block.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppTheme.systemBlack,
                          )),
                    );
                }
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
