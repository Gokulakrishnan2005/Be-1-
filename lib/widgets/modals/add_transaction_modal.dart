import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class AddTransactionModal extends StatefulWidget {
  final VoidCallback onAdded;

  const AddTransactionModal({super.key, required this.onAdded});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  TransactionType _selectedType = TransactionType.income;

  /// Calculates current liquid balance from all transactions
  double _calculateLiquidBalance(StorageService storage) {
    final txs = storage.getTransactions();
    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expenses = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final savings = txs
        .where((t) => t.type == TransactionType.savings)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final transfers = txs
        .where((t) => t.type == TransactionType.transfer)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return income - expenses - savings + transfers;
  }

  /// Calculates current savings balance from all transactions
  double _calculateSavingsBalance(StorageService storage) {
    final txs = storage.getTransactions();
    final savings = txs
        .where((t) => t.type == TransactionType.savings)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final transfers = txs
        .where((t) => t.type == TransactionType.transfer)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return savings - transfers;
  }

  void _saveTransaction() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    HapticWrapper.medium();
    final storage = context.read<StorageService>();

    // ─── OVERDRAFT INTERCEPT ─────────────────────────────────────
    if (_selectedType == TransactionType.expense) {
      final liquidBalance = _calculateLiquidBalance(storage);

      if (amount > liquidBalance) {
        final shortfall = amount - liquidBalance;
        final savingsBalance = _calculateSavingsBalance(storage);

        // Check if total wealth is sufficient
        if (shortfall > savingsBalance) {
          // Insufficient funds — can't cover even with savings
          final deficit = shortfall - savingsBalance;
          if (!mounted) return;
          await showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Insufficient Funds'),
              content: Text(
                'You are short by ₹${deficit.toStringAsFixed(2)} even with savings.\n\n'
                'Liquid: ₹${liquidBalance.toStringAsFixed(2)}\n'
                'Savings: ₹${savingsBalance.toStringAsFixed(2)}\n'
                'Expense: ₹${amount.toStringAsFixed(2)}',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
          return; // Halt the transaction
        }

        // Funds available — ask to use savings
        if (!mounted) return;
        final useSavings = await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Wallet Empty'),
            content: Text(
              'Your liquid balance is only ₹${liquidBalance.toStringAsFixed(2)}. '
              'Do you want to withdraw the remaining ₹${shortfall.toStringAsFixed(2)} '
              'from your Savings to cover this expense?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.activeBlue)),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Use Savings'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );

        if (useSavings != true) return; // User cancelled

        // ─── DOUBLE-ENTRY LEDGER: Step 1 — Transfer from Savings ───
        final transferTx = TransactionItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_transfer',
          title: 'Withdrew from Savings',
          amount: shortfall,
          date: DateTime.now(),
          type: TransactionType.transfer,
          category: 'Transfer',
        );
        await storage.saveTransaction(transferTx);
      }
    }

    // ─── NORMAL SAVE (or Step 2 of overdraft) ────────────────────
    final newTx = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: _selectedType,
      category: _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : null,
    );

    await storage.saveTransaction(newTx);
    widget.onAdded();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.systemGray6,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Ledger Entry',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoSlidingSegmentedControl<TransactionType>(
            groupValue: _selectedType,
            children: const {
              TransactionType.income: Text('Income'),
              TransactionType.expense: Text('Expense'),
              TransactionType.savings: Text('Savings'),
            },
            onValueChanged: (val) {
              if (val != null) {
                HapticWrapper.light();
                setState(() => _selectedType = val);
              }
            },
          ),
          const SizedBox(height: 24),
          CupertinoTextField(
            controller: _titleController,
            placeholder: 'Description (e.g. Salary, Coffee)',
            style: const TextStyle(color: AppTheme.systemBlack),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _categoryController,
            placeholder: 'Category (e.g. Food, Transport) - Optional',
            style: const TextStyle(color: AppTheme.systemBlack),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _amountController,
            placeholder: 'Amount (e.g. 50.00)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.systemBlack),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text('₹',
                  style: TextStyle(color: AppTheme.systemGray, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.systemBlack,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saveTransaction,
              child: const Text('Save Entry',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureCeramicWhite)),
            ),
          ),
        ],
      ),
    );
  }
}
