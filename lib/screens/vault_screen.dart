import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/credential.dart';
import '../services/storage_service.dart';
import '../services/vault_service.dart';
import '../theme/app_theme.dart';

class VaultScreen extends StatefulWidget {
  final String pin;
  const VaultScreen({super.key, required this.pin});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  void _addCredential() {
    final serviceCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Add Credential'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                  controller: serviceCtrl,
                  placeholder: 'Service (e.g. Gmail)',
                  style: const TextStyle(color: AppTheme.systemBlack)),
              const SizedBox(height: 8),
              CupertinoTextField(
                  controller: usernameCtrl,
                  placeholder: 'Username / Email',
                  style: const TextStyle(color: AppTheme.systemBlack)),
              const SizedBox(height: 8),
              CupertinoTextField(
                  controller: passwordCtrl,
                  placeholder: 'Password',
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.systemBlack)),
              const SizedBox(height: 8),
              CupertinoTextField(
                  controller: notesCtrl,
                  placeholder: 'Notes (optional)',
                  style: const TextStyle(color: AppTheme.systemBlack)),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
              child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () async {
              final service = serviceCtrl.text.trim();
              final username = usernameCtrl.text.trim();
              final password = passwordCtrl.text.trim();
              final notes = notesCtrl.text.trim();

              if (service.isEmpty || password.isEmpty) return;

              final cred = Credential(
                id: const Uuid().v4(),
                serviceName: service,
                username: username,
                encryptedPassword: VaultService.encrypt(password, widget.pin),
                encryptedNotes: VaultService.encrypt(notes, widget.pin),
              );

              final storage = context.read<StorageService>();
              await storage.saveCredential(cred);
              Navigator.pop(ctx);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final creds = storage.getCredentials();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        middle: const Text('My Vault',
            style: TextStyle(
                color: CupertinoColors.white, fontWeight: FontWeight.w700)),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.white,
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _addCredential,
          child: const Icon(CupertinoIcons.add, color: AppTheme.focusBlue),
        ),
      ),
      child: SafeArea(
        child: creds.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.lock_shield,
                        size: 64, color: AppTheme.systemGray.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('Vault is empty',
                        style: TextStyle(
                            color: AppTheme.systemGray, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Tap + to add credentials',
                        style: TextStyle(
                            color: AppTheme.systemGray, fontSize: 14)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: creds.length,
                itemBuilder: (context, index) {
                  final cred = creds[index];
                  return _CredentialTile(
                    cred: cred,
                    pin: widget.pin,
                    onDelete: () async {
                      await storage.deleteCredential(cred.id);
                      setState(() {});
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _CredentialTile extends StatefulWidget {
  final Credential cred;
  final String pin;
  final VoidCallback onDelete;

  const _CredentialTile(
      {required this.cred, required this.pin, required this.onDelete});

  @override
  State<_CredentialTile> createState() => _CredentialTileState();
}

class _CredentialTileState extends State<_CredentialTile> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final decryptedPwd = _showPassword
        ? VaultService.decrypt(widget.cred.encryptedPassword, widget.pin)
        : '••••••••';
    final decryptedNotes =
        VaultService.decrypt(widget.cred.encryptedNotes, widget.pin);

    return Dismissible(
      key: ValueKey(widget.cred.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirm = await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Delete Credential?'),
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
        if (confirm == true) widget.onDelete();
        return false; // Don't auto-dismiss, onDelete handles it
      },
      background: Container(
        color: CupertinoColors.systemRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(CupertinoIcons.trash_fill,
            color: CupertinoColors.white, size: 24),
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
            Row(
              children: [
                const Icon(CupertinoIcons.lock_fill,
                    size: 18, color: AppTheme.focusBlue),
                const SizedBox(width: 8),
                Text(widget.cred.serviceName,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.systemBlack)),
              ],
            ),
            if (widget.cred.username.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.cred.username,
                  style: const TextStyle(
                      fontSize: 15, color: AppTheme.systemGray)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(decryptedPwd,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: _showPassword ? 'Courier' : null,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemBlack,
                      )),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                  child: Icon(
                    _showPassword
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    size: 20,
                    color: AppTheme.systemGray,
                  ),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: () {
                    final pwd = VaultService.decrypt(
                        widget.cred.encryptedPassword, widget.pin);
                    Clipboard.setData(ClipboardData(text: pwd));
                  },
                  child: const Icon(CupertinoIcons.doc_on_doc,
                      size: 20, color: AppTheme.focusBlue),
                ),
              ],
            ),
            if (decryptedNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(decryptedNotes,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.systemGray)),
            ],
          ],
        ),
      ),
    );
  }
}
