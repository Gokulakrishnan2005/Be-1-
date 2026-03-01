import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'haptic_wrapper.dart';

class DataPortability extends StatelessWidget {
  const DataPortability({super.key});

  void _exportData(BuildContext context) async {
    HapticWrapper.medium();
    final storage = context.read<StorageService>();

    final Map<String, dynamic> exportData = {
      'skills': storage.getSkills().map((e) => e.toJson()).toList(),
      'sessions': storage.getSessions().map((e) => e.toJson()).toList(),
      'transactions': storage.getTransactions().map((e) => e.toJson()).toList(),
      'habits': storage.getHabits().map((e) => e.toJson()).toList(),
      'tasks': storage.getTasks().map((e) => e.toJson()).toList(),
      'goals': storage.getGoals().map((e) => e.toJson()).toList(),
      'wishlist': storage.getWishlistRaw(),
    };

    final jsonString = jsonEncode(exportData);

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/1_percent_better_export.json');
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: '1% Better Data Backup',
      );

      if (context.mounted && result.status == ShareResultStatus.success) {
        _showDialog(context, 'Exported', 'Data backed up successfully.');
      }
    } catch (e) {
      if (context.mounted) {
        // Fallback to clipboard
        await Clipboard.setData(ClipboardData(text: jsonString));
        _showDialog(context, 'Export Error',
            'Native share failed. Data copied to clipboard instead.\\n\\n$e');
      }
    }
  }

  void _importData(BuildContext context) async {
    HapticWrapper.medium();

    final data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data?.text == null) {
      if (context.mounted) {
        _showDialog(context, 'Import Failed', 'No text found in clipboard.');
      }
      return;
    }

    try {
      final decoded = jsonDecode(data!.text!);
      // Normally we would parse and save using StorageService here,
      // carefully merging or overwriting based on user preference.
      // For this demo, we validate the format roughly.
      if (decoded is Map && decoded.containsKey('skills')) {
        if (context.mounted) {
          _showDialog(context, 'Imported',
              'Mock data import successful! Please restart the app.');
        }
      } else {
        throw const FormatException('Invalid JSON format for 1% Better app.');
      }
    } catch (e) {
      if (context.mounted) {
        _showDialog(context, 'Import Failed', 'Invalid JSON from clipboard.');
      }
    }
  }

  void _showDialog(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child:
                const Text('OK', style: TextStyle(color: AppTheme.focusBlue)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('PORTABILITY',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.systemGray)),
      children: [
        CupertinoListTile(
          title: const Text('Export Backup JSON',
              style: TextStyle(color: AppTheme.focusBlue)),
          leading: const Icon(CupertinoIcons.square_arrow_up,
              color: AppTheme.focusBlue),
          onTap: () => _exportData(context),
        ),
        CupertinoListTile(
          title: const Text('Import JSON from Clipboard',
              style: TextStyle(color: AppTheme.focusBlue)),
          leading: const Icon(CupertinoIcons.square_arrow_down,
              color: AppTheme.focusBlue),
          onTap: () => _importData(context),
        ),
      ],
    );
  }
}
