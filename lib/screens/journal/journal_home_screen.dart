import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/section_header.dart';

class JournalHomeScreen extends ConsumerStatefulWidget {
  const JournalHomeScreen({super.key});

  @override
  ConsumerState<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends ConsumerState<JournalHomeScreen> {
  bool _showFavourites = false;

  void _confirmDelete(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete this entry?',
            style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
        content: Text(
          'This entry will be permanently removed.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(journalProvider.notifier).removeEntry(entry.id);
            },
            child: Text('Delete',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.dustyRose)),
          ),
        ],
      ),
    );
  }

  Color _stripColor(JournalEntry entry) {
    if (entry.isHardDate) return AppColors.softPurple;
    return switch (entry.intensityLevel) {
      JournalIntensityLevel.high => AppColors.dustyRose,
      JournalIntensityLevel.moderate => AppColors.warmAmber,
      JournalIntensityLevel.gentle => AppColors.sageGreen,
    };
  }

  Color _dotColor(JournalEntry entry) {
    return switch (entry.intensityLevel) {
      JournalIntensityLevel.high => const Color(0xFFE07070),
      JournalIntensityLevel.moderate => AppColors.warmMid,
      JournalIntensityLevel.gentle => AppColors.sageGreen,
    };
  }

  String _intensityLabel(JournalEntry entry) {
    return switch (entry.intensityLevel) {
      JournalIntensityLevel.high => 'High intensity',
      JournalIntensityLevel.moderate => 'Moderate',
      JournalIntensityLevel.gentle => 'Gentle',
    };
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(journalProvider);
    final entries = _showFavourites
        ? allEntries.where((e) => e.isFavourite).toList()
        : allEntries;
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';
    final now = DateTime.now();
    final monthFmt = DateFormat('MMMM yyyy');
    final thisMonthCount = entries
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .length;

    void showNewEntrySheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _NewEntrySheet(name: name),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _CircleBtn(
                          onTap: () =>
                              context.go('/home/dashboard'),
                          child: const Text('‹',
                              style: TextStyle(
                                  fontSize: 22,
                                  color:
                                      AppColors.textSecondary))),
                      Expanded(
                        child: Text('Journal',
                            style: AppTextStyles.screenTitle,
                            textAlign: TextAlign.center),
                      ),
                      _CircleBtn(
                          onTap: () => context.push(
                              '/home/journal/wave'),
                          child: const Icon(
                              Icons.show_chart_outlined,
                              size: 18,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All entries',
                        isSelected: !_showFavourites,
                        onTap: () => setState(() => _showFavourites = false),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '★ Favourites',
                        isSelected: _showFavourites,
                        onTap: () => setState(() => _showFavourites = true),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: entries.isEmpty
                      ? _EmptyState(
                          name: name,
                          onAdd: showNewEntrySheet,
                          isFavouritesFilter: _showFavourites,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              20, 12, 20, 100),
                          itemCount: entries.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Month summary
                                  Container(
                                    margin: const EdgeInsets
                                        .only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.amberTint,
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppDimensions
                                                  .cardRadius),
                                      border: const Border(
                                        left: BorderSide(
                                            color:
                                                AppColors.warmAmber,
                                            width: 4),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          monthFmt
                                              .format(now)
                                              .toUpperCase(),
                                          style: AppTextStyles
                                              .sectionLabel
                                              .copyWith(
                                                  color: AppColors
                                                      .amberDark),
                                        ),
                                        const SizedBox(height: 4),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '$thisMonthCount entries',
                                                style: AppTextStyles
                                                    .displayH1
                                                    .copyWith(
                                                        fontSize: 26),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' this month',
                                                style: AppTextStyles
                                                    .bodyMedium
                                                    .copyWith(
                                                        color: AppColors
                                                            .textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SectionHeader('RECENT ENTRIES'),
                                ],
                              );
                            }
                            final entry = entries[index - 1];
                            return _JournalCard(
                              entry: entry,
                              stripColor: _stripColor(entry),
                              dotColor: _dotColor(entry),
                              label: _intensityLabel(entry),
                              dateLabel: _relativeDate(entry.date),
                              onTap: () => context.push(
                                '/home/journal/entry/${entry.id}',
                                extra: entry,
                              ),
                              onEdit: () => context.push(
                                '/home/journal/freewrite',
                                extra: entry,
                              ),
                              onDelete: () => _confirmDelete(entry),
                            );
                          },
                        ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 90,
              right: 24,
              child: GestureDetector(
                onTap: showNewEntrySheet,
                child: Container(
                  width: AppDimensions.fabSize,
                  height: AppDimensions.fabSize,
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.amberDark, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.amberDark,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(child: CandleIcon(size: 24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final Color stripColor;
  final Color dotColor;
  final String label;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JournalCard({
    required this.entry,
    required this.stripColor,
    required this.dotColor,
    required this.label,
    required this.dateLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    void showMenu() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.bgWhite,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(sheetCtx).padding.bottom + 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _EntryMenuRow(
                icon: Icons.edit_outlined,
                label: 'Edit entry',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onEdit();
                },
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _EntryMenuRow(
                icon: Icons.delete_outline,
                label: 'Delete entry',
                color: AppColors.dustyRose,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      );
    }

    final menuBtn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: showMenu,
      child: const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(Icons.more_vert,
            size: 16, color: AppColors.textTertiary),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius:
              BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: entry.isHardDate
                ? AppColors.softPurple
                : AppColors.cardBorder,
            width: 2,
          ),
          boxShadow: entry.isHardDate
              ? const [
                  BoxShadow(
                    color: AppColors.softPurple,
                    offset: AppDimensions.neoShadowOffset,
                    blurRadius: AppDimensions.neoShadowBlur,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(AppDimensions.cardRadius - 1),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 21, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.isHardDate)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const CandleIcon(size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'HARD DATE',
                              style: AppTextStyles.aiAccent.copyWith(
                                color: AppColors.softPurple,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(dateLabel,
                                style: AppTextStyles.caption),
                            menuBtn,
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(dateLabel,
                                style: AppTextStyles.caption),
                            menuBtn,
                          ],
                        ),
                      ),
                    if (entry.isHardDate)
                      Text(
                        entry.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      entry.content.length > 80
                          ? '${entry.content.substring(0, 80)}…'
                          : entry.content,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 13, height: 1.55),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: dotColor, spreadRadius: 1)
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_wordCount(entry.content)} words · $label',
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: AppDimensions.colorStripWidth,
                  color: stripColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).length;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.warmAmber : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.warmAmber : AppColors.cardBorder,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String name;
  final VoidCallback onAdd;
  final bool isFavouritesFilter;
  const _EmptyState({required this.name, required this.onAdd, this.isFavouritesFilter = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CandleIcon(size: 40),
            const SizedBox(height: 16),
            Text(
              isFavouritesFilter ? 'No favourites yet.' : 'Your journal is waiting.',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFavouritesFilter
                  ? 'Star an entry to save it here.'
                  : 'Writing can help you process what you\'re carrying.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                height: 52,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.warmAmber, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.warmAmber,
                      offset: AppDimensions.neoShadowOffset,
                      blurRadius: AppDimensions.neoShadowBlur,
                    ),
                  ],
                ),
                child: Center(
                  child: Text('Write your first entry',
                      style: AppTextStyles.buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewEntrySheet extends StatelessWidget {
  final String name;
  const _NewEntrySheet({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.of(context).padding.bottom + 80),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New entry', style: AppTextStyles.screenTitle),
            const SizedBox(height: 16),
            _SheetOption(
              icon: '✨',
              title: 'Write with a prompt',
              subtitle: 'Luminary will offer a gentle starting point',
              onTap: () {
                Navigator.pop(context);
                context.push('/home/journal/prompted');
              },
            ),
            const SizedBox(height: 8),
            _SheetOption(
              icon: '✏️',
              title: 'Free write',
              subtitle: 'This is your space — write anything',
              onTap: () {
                Navigator.pop(context);
                context.push('/home/journal/freewrite');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _EntryMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _EntryMenuRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
