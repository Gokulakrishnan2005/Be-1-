import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ExperienceBoardScreen extends StatefulWidget {
  const ExperienceBoardScreen({super.key});

  @override
  State<ExperienceBoardScreen> createState() => _ExperienceBoardScreenState();
}

class _ExperienceBoardScreenState extends State<ExperienceBoardScreen> {
  int _selectedTab = 0; // 0 = Dreaming, 1 = Conquered

  void _addPlace() {
    final nameCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedMonth = 'Any time';

    final months = [
      'Any time',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: 480,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.pureCeramicWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Experience',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.systemBlack)),
              const SizedBox(height: 20),
              CupertinoTextField(
                  controller: nameCtrl,
                  placeholder: 'Place name (e.g. Tokyo)',
                  padding: const EdgeInsets.all(14),
                  style: const TextStyle(color: AppTheme.systemBlack),
                  decoration: BoxDecoration(
                    color: AppTheme.systemGray6,
                    borderRadius: BorderRadius.circular(10),
                  )),
              const SizedBox(height: 12),
              CupertinoTextField(
                  controller: countryCtrl,
                  placeholder: 'Country',
                  padding: const EdgeInsets.all(14),
                  style: const TextStyle(color: AppTheme.systemBlack),
                  decoration: BoxDecoration(
                    color: AppTheme.systemGray6,
                    borderRadius: BorderRadius.circular(10),
                  )),
              const SizedBox(height: 12),
              // Best time dropdown
              Row(
                children: [
                  const Text('Best time: ',
                      style:
                          TextStyle(color: AppTheme.systemGray, fontSize: 14)),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: ctx,
                        builder: (innerCtx) => Container(
                          height: 250,
                          color: AppTheme.pureCeramicWhite,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  CupertinoButton(
                                    child: const Text('Done'),
                                    onPressed: () => Navigator.pop(innerCtx),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  itemExtent: 36,
                                  scrollController: FixedExtentScrollController(
                                    initialItem: months.indexOf(selectedMonth),
                                  ),
                                  onSelectedItemChanged: (i) {
                                    setModalState(
                                        () => selectedMonth = months[i]);
                                  },
                                  children: months
                                      .map((m) => Center(child: Text(m)))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Text(selectedMonth,
                        style: const TextStyle(
                            color: AppTheme.focusBlue,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                  controller: notesCtrl,
                  placeholder: 'Notes (optional)',
                  padding: const EdgeInsets.all(14),
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.systemBlack),
                  decoration: BoxDecoration(
                    color: AppTheme.systemGray6,
                    borderRadius: BorderRadius.circular(10),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final country = countryCtrl.text.trim();
                    if (name.isEmpty) return;

                    final place = Place(
                      id: const Uuid().v4(),
                      name: name,
                      country: country,
                      bestTimeToVisit: selectedMonth,
                      notes: notesCtrl.text.trim(),
                    );

                    final storage = context.read<StorageService>();
                    await storage.savePlace(place);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('Add to Board',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allPlaces = storage.getPlaces();
    final dreaming = allPlaces.where((p) => !p.isVisited).toList();
    final conquered = allPlaces.where((p) => p.isVisited).toList();
    final currentList = _selectedTab == 0 ? dreaming : conquered;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Experience Board'),
        previousPageTitle: 'Profile',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _addPlace,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedTab,
                children: const {
                  0: Text('Dreaming ✨'),
                  1: Text('Conquered 🏆'),
                },
                onValueChanged: (val) {
                  setState(() => _selectedTab = val ?? 0);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: currentList.isEmpty
                  ? Center(
                      child: Text(
                        _selectedTab == 0
                            ? 'No destinations yet.\nTap + to dream big.'
                            : 'No places conquered yet.\nStart exploring!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.systemGray.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final place = currentList[index];
                        return Dismissible(
                          key: ValueKey(place.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            final confirm = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: const Text('Delete Place?'),
                                content:
                                    const Text('This action cannot be undone.'),
                                actions: [
                                  CupertinoDialogAction(
                                      child: const Text('Cancel'),
                                      onPressed: () =>
                                          Navigator.pop(ctx, false)),
                                  CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('Delete'),
                                      onPressed: () =>
                                          Navigator.pop(ctx, true)),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await storage.deletePlace(place.id);
                              setState(() {});
                            }
                            return false;
                          },
                          background: Container(
                            color: CupertinoColors.systemRed,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(CupertinoIcons.trash_fill,
                                color: CupertinoColors.white),
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
                                    Expanded(
                                      child: Text(place.name,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.systemBlack)),
                                    ),
                                    // Toggle visited
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minSize: 28,
                                      onPressed: () async {
                                        final updated = place.copyWith(
                                            newIsVisited: !place.isVisited);
                                        await storage.savePlace(updated);
                                        setState(() {});
                                      },
                                      child: Icon(
                                        place.isVisited
                                            ? CupertinoIcons
                                                .checkmark_circle_fill
                                            : CupertinoIcons.circle,
                                        color: place.isVisited
                                            ? AppTheme.growthGreen
                                            : AppTheme.systemGray,
                                        size: 24,
                                      ),
                                    ),
                                    // Open in Maps
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minSize: 28,
                                      onPressed: () async {
                                        final query = Uri.encodeComponent(
                                            '${place.name}, ${place.country}');
                                        final url = Uri.parse(
                                            'https://www.google.com/maps/search/?api=1&query=$query');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      child: const Icon(
                                          CupertinoIcons.map_pin_ellipse,
                                          size: 22,
                                          color: AppTheme.focusBlue),
                                    ),
                                  ],
                                ),
                                if (place.country.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(place.country,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.systemGray)),
                                ],
                                if (place.bestTimeToVisit.isNotEmpty &&
                                    place.bestTimeToVisit != 'Any time') ...[
                                  const SizedBox(height: 4),
                                  Text('🗓 Best time: ${place.bestTimeToVisit}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.focusBlue)),
                                ],
                                if (place.notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(place.notes,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.systemGray)),
                                ],
                              ],
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
