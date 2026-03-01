import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/squircle_card.dart';
import '../widgets/finance_chart.dart';
import '../widgets/modals/edit_transaction_modal.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => FinanceScreenState();
}

class FinanceScreenState extends State<FinanceScreen> {
  late final StorageService _storageService;
  List<TransactionItem> _transactions = [];

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _transactions = _storageService.getTransactions();
    });
  }

  void refresh() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Read actively from StorageService so reverse financial loops update UI instantly
    final storageService = context.watch<StorageService>();
    _transactions = storageService.getTransactions();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                    left: 24.0, right: 24.0, top: 40.0, bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Ledger',
                      style: TextStyle(
                        color: AppTheme.systemBlack,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 240,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFinanceModule('Total Income', TransactionType.income,
                        AppTheme.growthGreen),
                    _buildFinanceModule('Total Expenses',
                        TransactionType.expense, CupertinoColors.systemRed),
                    _buildSavingsModule(),
                    _buildLiquidBalanceModule(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 12,
                        color: AppTheme.systemGray,
                      ),
                      children: [
                        const TextSpan(text: 'Net Worth: '),
                        TextSpan(
                          text: '₹${_calculateNetWorth().toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._transactions.reversed.take(10).map((tx) {
                final isTransfer = tx.type == TransactionType.transfer;

                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: 12.0, left: 24.0, right: 24.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isTransfer
                        ? null // Transfer records are locked — no editing
                        : () {
                            showCupertinoModalPopup(
                              context: context,
                              barrierColor:
                                  AppTheme.systemBlack.withOpacity(0.4),
                              builder: (context) => EditTransactionModal(
                                transaction: tx,
                                onUpdated: refresh,
                              ),
                            );
                          },
                    child: SquircleCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tx.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isTransfer
                                      ? AppTheme.systemGray
                                      : AppTheme.systemBlack)),
                          Text(
                            tx.type == TransactionType.transfer
                                ? '↔ ₹${tx.amount.toStringAsFixed(2)}'
                                : '${tx.type == TransactionType.expense ? '-' : '+'}₹${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: tx.type == TransactionType.transfer
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
              }),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceModule(
      String title, TransactionType type, Color accentColor) {
    final filtered = _transactions.where((t) => t.type == type).toList();
    final total = filtered.fold<double>(0, (sum, item) => sum + item.amount);

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SquircleCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: AppTheme.systemGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Courier',
                letterSpacing: -1,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 100, // Space for the graph
              child: FinanceChart(transactions: _transactions, type: type),
            ),
          ],
        ),
      ),
    );
  }

  /// Total Saved card: savings deposits MINUS transfer withdrawals.
  Widget _buildSavingsModule() {
    final savingsDeposits = _transactions
        .where((t) => t.type == TransactionType.savings)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final transferWithdrawals = _transactions
        .where((t) => t.type == TransactionType.transfer)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final netSavings = savingsDeposits - transferWithdrawals;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SquircleCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Saved',
              style: TextStyle(
                  color: AppTheme.systemGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${netSavings.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Courier',
                letterSpacing: -1,
                fontWeight: FontWeight.w900,
                color: netSavings >= 0
                    ? AppTheme.focusBlue
                    : CupertinoColors.systemRed,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 100,
              child: FinanceChart(
                  transactions: _transactions, type: TransactionType.savings),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateNetWorth() {
    final income = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenses = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final savings = _transactions
        .where((t) => t.type == TransactionType.savings)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final transfers = _transactions
        .where((t) => t.type == TransactionType.transfer)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final liquid = income - expenses - savings + transfers;
    return liquid + (savings - transfers);
  }

  Widget _buildLiquidBalanceModule() {
    final income = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenses = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final savings = _transactions
        .where((t) => t.type == TransactionType.savings)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final transfers = _transactions
        .where((t) => t.type == TransactionType.transfer)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final liquid = income - (expenses + savings) + transfers;
    final accentColor =
        liquid >= 0 ? AppTheme.focusBlue : CupertinoColors.systemRed;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SquircleCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liquid Balance',
              style: TextStyle(
                  color: AppTheme.systemGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${liquid.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Courier',
                letterSpacing: -1,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 100), // Placeholder for symmetry
          ],
        ),
      ),
    );
  }
}
