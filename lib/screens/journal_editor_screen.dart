import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? existingEntry;
  const JournalEditorScreen({super.key, this.existingEntry});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late TextEditingController _titleController;
  late List<ContentBlock> _blocks;
  final List<TextEditingController> _blockControllers = [];
  late String _mood;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _titleController =
          TextEditingController(text: widget.existingEntry!.title);
      _blocks = List.from(widget.existingEntry!.contentBlocks);
      _mood = widget.existingEntry!.mood;
    } else {
      _titleController = TextEditingController();
      _blocks = [ContentBlock(type: 'paragraph', content: '')];
      _mood = 'positive';
    }
    _syncControllers();
  }

  void _syncControllers() {
    _blockControllers.clear();
    for (final block in _blocks) {
      _blockControllers.add(TextEditingController(text: block.content));
    }
  }

  void _addBlock(String type) async {
    if (type == 'image') {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return;

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'journal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        await File(picked.path).copy(savedPath);

        setState(() {
          _blocks.add(ContentBlock(type: 'image', content: savedPath));
          _blockControllers.add(TextEditingController(text: savedPath));
        });
      } catch (_) {
        // Image picking not supported or cancelled
      }
    } else {
      setState(() {
        _blocks.add(ContentBlock(type: type, content: ''));
        _blockControllers.add(TextEditingController());
      });
    }
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      _blockControllers.removeAt(index);
    });
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Sync text controllers back to blocks
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].type != 'image') {
        _blocks[i].content = _blockControllers[i].text;
      }
    }

    // Remove empty non-image blocks
    _blocks.removeWhere((b) => b.type != 'image' && b.content.trim().isEmpty);

    final entry = JournalEntry(
      id: widget.existingEntry?.id ?? const Uuid().v4(),
      title: title,
      date: widget.existingEntry?.date ?? DateTime.now(),
      mood: _mood,
      contentBlocks: _blocks,
    );

    final storage = context.read<StorageService>();
    await storage.saveJournalEntry(entry);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.pureCeramicWhite,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.existingEntry != null ? 'Edit Entry' : 'New Entry'),
        previousPageTitle: 'Journal',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child:
              const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    CupertinoTextField.borderless(
                      controller: _titleController,
                      placeholder: 'Title',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.systemBlack,
                      ),
                      placeholderStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.systemGray.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mood toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mood = _mood == 'positive' ? 'negative' : 'positive';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _mood == 'positive'
                              ? const Color(0xFF34C759).withOpacity(0.12)
                              : const Color(0xFFFF3B30).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _mood == 'positive' ? '☀️' : '🌧️',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _mood == 'positive'
                                  ? 'Positive Entry'
                                  : 'Negative Entry',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _mood == 'positive'
                                    ? const Color(0xFF34C759)
                                    : const Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content blocks
                    ...List.generate(_blocks.length, (i) {
                      final block = _blocks[i];

                      if (block.type == 'image') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(block.content),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    color: AppTheme.systemGray6,
                                    child: const Center(
                                        child: Text('Image not found')),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeBlock(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: CupertinoColors.systemRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(CupertinoIcons.xmark,
                                        size: 14, color: CupertinoColors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      double fontSize;
                      FontWeight fontWeight;
                      switch (block.type) {
                        case 'heading':
                          fontSize = 22;
                          fontWeight = FontWeight.w700;
                          break;
                        case 'subheading':
                          fontSize = 18;
                          fontWeight = FontWeight.w600;
                          break;
                        default:
                          fontSize = 16;
                          fontWeight = FontWeight.w400;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CupertinoTextField.borderless(
                                controller: _blockControllers[i],
                                placeholder: block.type == 'heading'
                                    ? 'Heading'
                                    : block.type == 'subheading'
                                        ? 'Subheading'
                                        : 'Write something...',
                                maxLines: null,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: fontWeight,
                                  color: AppTheme.systemBlack,
                                ),
                              ),
                            ),
                            if (_blocks.length > 1)
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 24,
                                onPressed: () => _removeBlock(i),
                                child: const Icon(CupertinoIcons.minus_circle,
                                    size: 18, color: AppTheme.systemGray),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.systemGray6,
                border: Border(
                    top: BorderSide(
                        color: AppTheme.systemGray.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolbarButton(
                      icon: CupertinoIcons.textformat,
                      label: 'H1',
                      onTap: () => _addBlock('heading')),
                  _ToolbarButton(
                      icon: CupertinoIcons.textformat_alt,
                      label: 'H2',
                      onTap: () => _addBlock('subheading')),
                  _ToolbarButton(
                      icon: CupertinoIcons.text_alignleft,
                      label: 'Text',
                      onTap: () => _addBlock('paragraph')),
                  _ToolbarButton(
                      icon: CupertinoIcons.photo,
                      label: 'Image',
                      onTap: () => _addBlock('image')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolbarButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppTheme.focusBlue),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.systemGray,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
