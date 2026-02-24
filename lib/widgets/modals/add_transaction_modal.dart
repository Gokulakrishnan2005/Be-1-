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
  TransactionType _selectedType = TransactionType.income;

  void _saveTransaction() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (title.isNotEmpty && amount > 0) {
      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final newTx = TransactionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        date: DateTime.now(),
        type: _selectedType,
      );

      await storage.saveTransaction(newTx);
      widget.onAdded();
      Navigator.of(context).pop();
    }
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
              color: _selectedType == TransactionType.expense
                  ? CupertinoColors.systemRed
                  : AppTheme.growthGreen,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saveTransaction,
              child: const Text('Save Entry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
