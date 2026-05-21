import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

class JournalEntryViewScreen extends ConsumerWidget {
  final JournalEntry entry;
  const JournalEntryViewScreen({super.key, required this.entry});

  Color _stripColor() {
    if (entry.isHardDate) return AppColors.softPurple;
    return switch (entry.intensityLevel) {
      JournalIntensityLevel.high => const Color(0xFFE07070),
      JournalIntensityLevel.moderate => AppColors.warmAmber,
      JournalIntensityLevel.gentle => AppColors.sageGreen,
    };
  }

  String _intensityLabel() {
    return switch (entry.intensityLevel) {
      JournalIntensityLevel.high => 'High intensity',
      JournalIntensityLevel.moderate => 'Moderate',
      JournalIntensityLevel.gentle => 'Gentle',
    };
  }

  int _wordCount() =>
      entry.content.trim().split(RegExp(r'\s+')).length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEntry = ref.watch(journalProvider).firstWhere(
      (e) => e.id == entry.id,
      orElse: () => entry,
    );
    final titleFmt = DateFormat('d MMMM yyyy');
    final title = titleFmt.format(entry.date);

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    onTap: () => context.pop(),
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text(title,
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  _CircleBtn(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(journalProvider.notifier).toggleFavourite(entry.id);
                    },
                    child: Text(
                      currentEntry.isFavourite ? '★' : '☆',
                      style: TextStyle(
                        fontSize: 18,
                        color: currentEntry.isFavourite ? AppColors.warmAmber : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intensity strip
                    Container(
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(
                          colors: [_stripColor(), AppColors.warmAmber],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.divider,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    // Hard date badge
                    if (entry.isHardDate) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.purpleTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CandleIcon(size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'HARD DATE',
                              style: AppTextStyles.aiAccent
                                  .copyWith(
                                color: AppColors.softPurple,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Prompt card (if prompted entry)
                    if (entry.promptUsed != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.purpleTint,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.cardRadius),
                          border: const Border(
                            left: BorderSide(
                                color: AppColors.softPurple,
                                width: 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROMPT',
                              style: AppTextStyles.sectionLabel
                                  .copyWith(
                                      color: AppColors.softPurple),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.promptUsed!,
                              style: AppTextStyles.bodyLight,
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Entry title
                    Text(entry.title,
                        style: AppTextStyles.displayH1),
                    const SizedBox(height: 12),
                    // Entry body
                    Text(
                      entry.content,
                      style: AppTextStyles.bodyLight.copyWith(
                        fontSize: 17,
                        height: 1.75,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Metadata
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _stripColor(),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: _stripColor(),
                                  spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_wordCount()} words · ${_intensityLabel()}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Share ghost link
                    Center(
                      child: GestureDetector(
                        onTap: () {/* TODO: share excerpt */},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.divider,
                                width: 1.5),
                          ),
                          child: Text(
                            'Share excerpt to community',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
