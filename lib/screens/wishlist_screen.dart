import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/wishlist_item.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/haptic_wrapper.dart';
import '../widgets/squircle_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final StorageService _storageService;
  List<WishlistItem> _items = [];

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _loadData();
  }

  void _loadData() {
    final rawList = _storageService.getWishlistRaw();
    setState(() {
      _items = rawList.map((json) => WishlistItem.fromJson(json)).toList();
    });
  }

  // ─── MARK AS BOUGHT ───────────────────────────────────────────
  void _markAsBought(WishlistItem item, double liquidBalance) async {
    if (item.isBought) return;

    if (!item.isBought && liquidBalance < item.price) {
      final proceed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Negative Capital Warning',
              style: TextStyle(fontWeight: FontWeight.bold)),
          message: const Text(
              'This purchase exceeds your Liquid Balance and will result in negative capital. Proceed?'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ),
      );
      if (proceed != true) return;
    }

    _processPurchase(item);
  }

  void _processPurchase(WishlistItem item) async {
    HapticWrapper.heavy();
    final isNewlyBought = !item.isBought;
    final updatedItem = WishlistItem(
      id: item.id,
      title: item.title,
      price: item.price,
      isBought: isNewlyBought,
      createdAt: item.createdAt,
    );

    int idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) _items[idx] = updatedItem;

    if (isNewlyBought) {
      final newTx = TransactionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '[Wishlist] ${item.title}',
        amount: item.price,
        date: DateTime.now(),
        type: TransactionType.expense,
        linkedWishlistId: item.id,
      );
      await _storageService.saveTransaction(newTx);
    }

    await _storageService
        .saveWishlistRaw(_items.map((i) => i.toJson()).toList());
    _loadData();
  }

  // ─── DELETE ITEM ──────────────────────────────────────────────
  Future<void> _deleteItem(WishlistItem item) async {
    if (item.isBought) {
      // Ask if they want to undo the linked expense
      final undoExpense = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text('Delete "${item.title}"?',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          message: const Text(
              'This item was already purchased. Do you also want to undo the associated expense in Finance?'),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete & Undo Expense'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Delete (Keep Financial Record)'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ),
      );

      if (undoExpense == null) return; // Cancelled

      if (undoExpense) {
        // Remove linked transaction from finance
        final txs = _storageService.getTransactions();
        final linkedTx = txs.where((t) => t.linkedWishlistId == item.id);
        for (final tx in linkedTx) {
          await _storageService.deleteTransaction(tx.id);
        }
      }
    } else {
      // Simple confirmation for active items
      final confirm = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text('Delete "${item.title}"?',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          message: const Text('This item will be permanently removed.'),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ),
      );
      if (confirm != true) return;
    }

    HapticWrapper.heavy();
    _items.removeWhere((i) => i.id == item.id);
    await _storageService
        .saveWishlistRaw(_items.map((i) => i.toJson()).toList());
    _loadData();
  }

  // ─── EDIT ITEM ────────────────────────────────────────────────
  void _showEditItemModal(WishlistItem item) {
    final titleCtrl = TextEditingController(text: item.title);
    final priceCtrl =
        TextEditingController(text: item.price.toStringAsFixed(0));

    showCupertinoModalPopup(
      context: context,
      barrierColor: AppTheme.systemBlack.withAlpha(100),
      builder: (ctx) {
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Wish',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.systemBlack,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoTextField(
                controller: titleCtrl,
                placeholder: 'Item Name (e.g. MacBook Pro)',
                placeholderStyle: TextStyle(
                  color: AppTheme.systemBlack.withOpacity(0.4),
                ),
                style: const TextStyle(color: AppTheme.systemBlack),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.pureCeramicWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: priceCtrl,
                placeholder: 'Est. Cost (e.g. 1999)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !item.isBought, // Disable price edit for bought items
                style: TextStyle(
                  color: item.isBought
                      ? AppTheme.systemGray
                      : AppTheme.systemBlack,
                ),
                placeholderStyle: TextStyle(
                  color: AppTheme.systemBlack.withOpacity(0.4),
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.isBought
                      ? AppTheme.systemGray6
                      : AppTheme.pureCeramicWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text('₹',
                      style: TextStyle(
                          color: item.isBought
                              ? AppTheme.systemGray.withOpacity(0.4)
                              : AppTheme.systemGray,
                          fontSize: 18)),
                ),
              ),
              if (item.isBought)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Price is locked for purchased items.',
                    style: TextStyle(
                      color: AppTheme.systemGray,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppTheme.systemBlack,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? item.price;
                    if (title.isNotEmpty) {
                      HapticWrapper.medium();
                      final updatedItem = WishlistItem(
                        id: item.id,
                        title: title,
                        price: item.isBought ? item.price : price,
                        isBought: item.isBought,
                        createdAt: item.createdAt,
                      );
                      int idx = _items.indexWhere((i) => i.id == item.id);
                      if (idx != -1) _items[idx] = updatedItem;
                      await _storageService.saveWishlistRaw(
                          _items.map((i) => i.toJson()).toList());
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _loadData();
                    }
                  },
                  child: const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pureCeramicWhite)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── ADD ITEM MODAL ───────────────────────────────────────────
  void _showAddItemModal() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      barrierColor: AppTheme.systemBlack.withAlpha(100),
      builder: (ctx) {
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Desire',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.systemBlack,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoTextField(
                controller: titleCtrl,
                placeholder: 'Item Name (e.g. MacBook Pro)',
                placeholderStyle: TextStyle(
                  color: AppTheme.systemBlack.withOpacity(0.4),
                ),
                style: const TextStyle(color: AppTheme.systemBlack),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.pureCeramicWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: priceCtrl,
                placeholder: 'Est. Cost (e.g. 1999)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                placeholderStyle: TextStyle(
                  color: AppTheme.systemBlack.withOpacity(0.4),
                ),
                style: const TextStyle(color: AppTheme.systemBlack),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.pureCeramicWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text('₹',
                      style:
                          TextStyle(color: AppTheme.systemGray, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppTheme.systemBlack,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;
                    if (title.isNotEmpty && price > 0) {
                      final newItem = WishlistItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          price: price);
                      _items.add(newItem);
                      await _storageService.saveWishlistRaw(
                          _items.map((i) => i.toJson()).toList());
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _loadData();
                    }
                  },
                  child: const Text('Add to Wishlist',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pureCeramicWhite)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final txs = storage.getTransactions();
    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, i) => sum + i.amount);
    final expenses = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, i) => sum + i.amount);
    final savings = txs
        .where((t) => t.type == TransactionType.savings)
        .fold<double>(0, (sum, i) => sum + i.amount);
    final liquidBalance = income - expenses - savings;

    final double capitalRequired =
        _items.where((i) => !i.isBought).fold(0.0, (sum, i) => sum + i.price);
    final double capitalDeployed =
        _items.where((i) => i.isBought).fold(0.0, (sum, i) => sum + i.price);

    final activeItems = _items.where((i) => !i.isBought).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final boughtItems = _items.where((i) => i.isBought).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Wishlist'),
        previousPageTitle: 'Profile',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddItemModal,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                      child: SquircleCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Capital Required',
                                style: TextStyle(
                                    color: AppTheme.systemGray,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('₹${capitalRequired.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Courier')),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                      child: SquircleCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Capital Deployed',
                                style: TextStyle(
                                    color: AppTheme.systemGray,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('₹${capitalDeployed.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Courier',
                                    color: AppTheme.growthGreen)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (activeItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 24.0, top: 32, bottom: 8),
                  child: Text('ACTIVE DESIRES',
                      style: TextStyle(
                          color: AppTheme.systemGray,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.2)),
                ),
                ...activeItems
                    .map((item) => _buildWishlistItem(item, liquidBalance)),
              ],
              if (boughtItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 24.0, top: 32, bottom: 8),
                  child: Text('ACQUIRED',
                      style: TextStyle(
                          color: AppTheme.systemGray,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.2)),
                ),
                ...boughtItems
                    .map((item) => _buildWishlistItem(item, liquidBalance)),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WISHLIST ITEM ROW ────────────────────────────────────────
  Widget _buildWishlistItem(WishlistItem item, double liquidBalance) {
    final bool isFunded = !item.isBought && (liquidBalance >= item.price);
    final double progress = (liquidBalance / item.price).clamp(0.0, 1.0);

    Widget content = SquircleCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration:
                            item.isBought ? TextDecoration.lineThrough : null,
                        color: item.isBought
                            ? AppTheme.systemGray
                            : AppTheme.systemBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontFamily: 'Courier',
                            color: AppTheme.systemGray,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: item.isBought
                    ? AppTheme.systemGray6
                    : (isFunded ? AppTheme.growthGreen : AppTheme.systemBlack),
                borderRadius: BorderRadius.circular(20),
                onPressed: () => _markAsBought(item, liquidBalance),
                child: Text(
                  item.isBought ? 'Acquired' : 'Mark Bought',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: item.isBought
                        ? AppTheme.systemGray
                        : AppTheme.pureCeramicWhite,
                  ),
                ),
              ),
            ],
          ),
          if (!item.isBought) ...[
            const SizedBox(height: 16),
            if (isFunded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.growthGreen.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill,
                        size: 14, color: AppTheme.growthGreen),
                    SizedBox(width: 4),
                    Text('₹ Funded. Ready to Buy.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.growthGreen,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: AppTheme.systemGray6,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          color: AppTheme.focusBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${liquidBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: liquidBalance < 0
                                  ? AppTheme.systemRed
                                  : AppTheme.systemGray,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold)),
                      Text('₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.systemGray,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
          ],
        ],
      ),
    );

    // Wrap with GestureDetector for tap-to-edit
    Widget tappableContent = GestureDetector(
      onTap: () => _showEditItemModal(item),
      child: isFunded
          ? Transform.scale(
              scale: 1.02,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.growthGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.growthGreen.withAlpha(40),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: content,
              ),
            )
          : content,
    );

    // Wrap with Dismissible for swipe-to-delete
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          await _deleteItem(item);
          // Always return false — we handle deletion ourselves
          // so the Dismissible doesn't auto-remove the widget
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: CupertinoColors.destructiveRed,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(CupertinoIcons.trash_fill,
              color: CupertinoColors.white, size: 28),
        ),
        child: tappableContent,
      ),
    );
  }
}
