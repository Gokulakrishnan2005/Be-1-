import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../services/vault_service.dart';
import '../theme/app_theme.dart';
import 'vault_screen.dart';

class VaultPinScreen extends StatefulWidget {
  const VaultPinScreen({super.key});

  @override
  State<VaultPinScreen> createState() => _VaultPinScreenState();
}

class _VaultPinScreenState extends State<VaultPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isSetupMode = false;
  bool _isConfirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _isSetupMode = storage.getVaultPin() == null;
  }

  void _onDigit(String digit) {
    setState(() {
      _error = null;
      if (_isConfirming) {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _verifySetup();
      } else {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          if (_isSetupMode) {
            // Validate PIN strength
            final err = VaultService.validatePin(_pin);
            if (err != null) {
              _error = err;
              _pin = '';
            } else {
              _isConfirming = true;
            }
          } else {
            _verifyUnlock();
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _verifySetup() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs don\'t match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    final storage = context.read<StorageService>();
    await storage.setVaultPin(_pin);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => VaultScreen(pin: _pin)),
      );
    }
  }

  void _verifyUnlock() {
    final storage = context.read<StorageService>();
    final storedPin = storage.getVaultPin();

    if (_pin == storedPin) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => VaultScreen(pin: _pin)),
      );
    } else {
      setState(() {
        _error = 'Wrong PIN. Try again.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;
    final title = _isSetupMode
        ? (_isConfirming ? 'Confirm PIN' : 'Set Your PIN')
        : 'Enter PIN';
    final subtitle = _isSetupMode && !_isConfirming
        ? 'Choose a 4-digit PIN for your Vault'
        : _isSetupMode && _isConfirming
            ? 'Re-enter PIN to confirm'
            : 'Unlock your credentials';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        middle: Text(title,
            style: const TextStyle(
                color: CupertinoColors.white, fontWeight: FontWeight.w600)),
        previousPageTitle: 'Profile',
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(CupertinoIcons.lock_shield_fill,
                size: 48, color: AppTheme.focusBlue),
            const SizedBox(height: 16),
            Text(subtitle,
                style: const TextStyle(
                    color: CupertinoColors.systemGrey, fontSize: 15)),
            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppTheme.focusBlue
                        : CupertinoColors.systemGrey.withOpacity(0.3),
                    border: Border.all(
                        color: AppTheme.focusBlue.withOpacity(0.5), width: 1.5),
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(
                      color: CupertinoColors.systemRed, fontSize: 14)),
            ],

            const Spacer(),

            // Number pad
            _buildNumpad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80);
              return CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: key == '⌫' ? _onDelete : () => _onDigit(key),
                child: Container(
                  width: 80,
                  height: 72,
                  alignment: Alignment.center,
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
