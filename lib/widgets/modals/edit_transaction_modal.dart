import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class EditTransactionModal extends StatefulWidget {
  final TransactionItem transaction;
  final VoidCallback onUpdated;

  const EditTransactionModal(
      {super.key, required this.transaction, required this.onUpdated});

  @override
  State<EditTransactionModal> createState() => _EditTransactionModalState();
}

class _EditTransactionModalState extends State<EditTransactionModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(2));
    _selectedType = widget.transaction.type;
  }

  void _saveTransaction() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (title.isNotEmpty && amount > 0) {
      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final updatedTx = TransactionItem(
        id: widget.transaction.id,
        title: title,
        amount: amount,
        date: widget.transaction.date,
        type: _selectedType,
      );

      await storage.saveTransaction(updatedTx);
      widget.onUpdated();
      Navigator.of(context).pop();
    }
  }

  void _deleteTransaction() async {
    HapticWrapper.heavy();
    final storage = context.read<StorageService>();
    await storage.deleteTransaction(widget.transaction.id);
    widget.onUpdated();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Entry',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.systemBlack,
                  letterSpacing: -0.5,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _deleteTransaction,
                child: const Icon(CupertinoIcons.trash,
                    color: CupertinoColors.systemRed),
              ),
            ],
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
              child: const Text('Update Entry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
