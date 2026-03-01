import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/squircle_card.dart';
import '../../widgets/modals/edit_transaction_modal.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedTags = [];

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        DateTime tempStart =
            _startDate ?? DateTime.now().subtract(const Duration(days: 30));
        DateTime tempEnd = _endDate ?? DateTime.now();

        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: 400,
            color: AppTheme.systemGray6,
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoButton(
                        child: const Text('Apply'),
                        onPressed: () {
                          setState(() {
                            _startDate = tempStart;
                            _endDate = tempEnd;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const Text('Start Date',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 100,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: tempStart,
                      maximumDate: tempEnd,
                      onDateTimeChanged: (DateTime newDate) {
                        setModalState(() {
                          tempStart = newDate;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('End Date',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 100,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: tempEnd,
                      minimumDate: tempStart,
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (DateTime newDate) {
                        setModalState(() {
                          tempEnd = newDate;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showTagPicker(List<String> availableTags) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: 400,
            color: AppTheme.systemGray6,
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Clear'),
                        onPressed: () {
                          setState(() {
                            _selectedTags.clear();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableTags.length,
                      itemBuilder: (context, index) {
                        final tag = availableTags[index];
                        final isSelected = _selectedTags.contains(tag);
                        return CupertinoListTile(
                          title: Text(tag),
                          trailing: isSelected
                              ? const Icon(CupertinoIcons.checkmark_alt,
                                  color: AppTheme.focusBlue)
                              : null,
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                            setState(() {}); // Trigger rebuild behind modal
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allTransactions = storage.getTransactions();

    // Extract unique tags
    final availableTags = allTransactions
        .where((t) => t.category != null && t.category!.isNotEmpty)
        .map((t) => t.category!)
        .toSet()
        .toList();

    // Apply Filters
    var filtered = allTransactions.where((t) {
      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        // Normalize times to midnight for clean boundaries
        final start =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        matchesDate = t.date.isAfter(start) && t.date.isBefore(end);
      }

      bool matchesTag = true;
      if (_selectedTags.isNotEmpty) {
        matchesTag = t.category != null && _selectedTags.contains(t.category);
      }

      return matchesDate && matchesTag;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    // Determine Filter Button Texts
    String dateLabel = 'Date Range';
    if (_startDate != null && _endDate != null) {
      dateLabel =
          '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}';
    }

    String tagLabel = 'Categories';
    if (_selectedTags.isNotEmpty) {
      if (_selectedTags.length == 1) {
        tagLabel = _selectedTags.first;
      } else {
        tagLabel = '${_selectedTags.length} Categories';
      }
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ledger History'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: _startDate != null
                          ? AppTheme.focusBlue
                          : AppTheme.pureCeramicWhite,
                      onPressed: _showDatePicker,
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                            color: _startDate != null
                                ? AppTheme.pureCeramicWhite
                                : AppTheme.focusBlue,
                            fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: _selectedTags.isNotEmpty
                          ? AppTheme.focusBlue
                          : AppTheme.pureCeramicWhite,
                      onPressed: availableTags.isEmpty
                          ? null
                          : () => _showTagPicker(availableTags),
                      child: Text(
                        tagLabel,
                        style: TextStyle(
                            color: _selectedTags.isNotEmpty
                                ? AppTheme.pureCeramicWhite
                                : (availableTags.isEmpty
                                    ? AppTheme.systemGray
                                    : AppTheme.focusBlue),
                            fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List View
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(
                            color: AppTheme.systemGray.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isTransfer = tx.type == TransactionType.transfer;

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 12.0, left: 16.0, right: 16.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isTransfer
                                ? null // Transfer records are locked
                                : () {
                                    showCupertinoModalPopup(
                                      context: context,
                                      barrierColor:
                                          AppTheme.systemBlack.withOpacity(0.4),
                                      builder: (context) =>
                                          EditTransactionModal(
                                        transaction: tx,
                                        onUpdated: () {},
                                      ),
                                    );
                                  },
                            child: SquircleCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tx.title,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: isTransfer
                                                  ? AppTheme.systemGray
                                                  : AppTheme.systemBlack)),
                                      if (tx.category != null &&
                                          tx.category!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(tx.category!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.systemGray)),
                                        )
                                    ],
                                  ),
                                  Text(
                                    tx.type == TransactionType.transfer
                                        ? '↔ ₹${tx.amount.toStringAsFixed(2)}'
                                        : '${tx.type == TransactionType.expense ? '-' : '+'}₹${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      color: isTransfer
                                          ? AppTheme.systemGray
                                          : tx.type == TransactionType.expense
                                              ? AppTheme.systemBlack
                                              : AppTheme.growthGreen,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
