import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/journal_provider.dart';
import '../../providers/memory_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/section_header.dart';

class AiMemoryControlsScreen extends ConsumerWidget {
  const AiMemoryControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref
        .watch(memoryProvider)
        .where((m) => m.isSharedWithAI)
        .toList();
    final journalEntries = ref
        .watch(journalProvider)
        .where((e) => e.isSharedWithAI)
        .toList();

    final totalShared = memories.length + journalEntries.length;

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
                    child: Text('AI Memory Controls',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 40),
                children: [
                  // Explanation card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.purpleTint,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.cardRadius),
                      border: Border.all(
                          color: AppColors.softPurple,
                          width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 18,
                            color: AppColors.softPurple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your companion uses these memories to personalise conversations. You control what it knows.',
                            style:
                                AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.softPurple,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (totalShared == 0) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No memories or journal entries are currently shared with your companion.',
                          style: AppTextStyles.bodyMedium
                              .copyWith(
                                  color:
                                      AppColors.textSecondary,
                                  height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── Shared memories ─────────────────────────────
                    if (memories.isNotEmpty) ...[
                      SectionHeader('SHARED MEMORIES',
                          padding: const EdgeInsets.fromLTRB(
                              2, 0, 2, 10)),
                      ...memories.map((m) => Container(
                            margin: const EdgeInsets.only(
                                bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bgWhite,
                              borderRadius:
                                  BorderRadius.circular(
                                      AppDimensions.cardRadius),
                              border: Border.all(
                                  color:
                                      AppColors.cardBorder,
                                  width: 2),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          m.title ??
                                              'Untitled memory',
                                          style: AppTextStyles
                                              .bodyMedium
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600),
                                        ),
                                        if (m.textContent !=
                                            null)
                                          Text(
                                            m.textContent!
                                                        .length >
                                                    60
                                                ? '${m.textContent!.substring(0, 60)}…'
                                                : m.textContent!,
                                            style:
                                                AppTextStyles
                                                    .caption,
                                          ),
                                        if (m.voiceNoteUrl !=
                                            null)
                                          Text('Voice note',
                                              style:
                                                  AppTextStyles
                                                      .caption),
                                      ],
                                    ),
                                  ),
                                  Semantics(
                                    label:
                                        'Revoke sharing for ${m.title ?? 'memory'}',
                                    button: true,
                                    child: Switch(
                                      value: m.isSharedWithAI,
                                      onChanged: (v) => ref
                                          .read(memoryProvider
                                              .notifier)
                                          .updateSharedWithAI(
                                              m.id, v),
                                      activeThumbColor:
                                          AppColors.softPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── Shared journal entries ───────────────────────
                    if (journalEntries.isNotEmpty) ...[
                      SectionHeader('SHARED JOURNAL ENTRIES',
                          padding: const EdgeInsets.fromLTRB(
                              2, 0, 2, 10)),
                      ...journalEntries.map((e) => Container(
                            margin: const EdgeInsets.only(
                                bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bgWhite,
                              borderRadius:
                                  BorderRadius.circular(
                                      AppDimensions.cardRadius),
                              border: Border.all(
                                  color:
                                      AppColors.cardBorder,
                                  width: 2),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          e.title,
                                          style: AppTextStyles
                                              .bodyMedium
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600),
                                        ),
                                        Text(
                                          e.content.length >
                                                  60
                                              ? '${e.content.substring(0, 60)}…'
                                              : e.content,
                                          style: AppTextStyles
                                              .caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Semantics(
                                    label:
                                        'Revoke sharing for journal entry ${e.title}',
                                    button: true,
                                    child: Switch(
                                      value: e.isSharedWithAI,
                                      onChanged: (v) => ref
                                          .read(journalProvider
                                              .notifier)
                                          .updateSharedWithAI(
                                              e.id, v),
                                      activeThumbColor:
                                          AppColors.softPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Clear all button
                    LuminaryButton(
                      label: 'Clear all AI context',
                      style: LuminaryButtonStyle.danger,
                      onTap: () =>
                          _confirmClearAll(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Clear all AI context?',
            style: AppTextStyles.screenTitle
                .copyWith(fontSize: 18)),
        content: Text(
          'Your companion will no longer reference any of your memories or journal entries. You can re-share them at any time.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.buttonLabel
                    .copyWith(
                        color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Revoke all shared memories
              for (final m in ref
                  .read(memoryProvider)
                  .where((m) => m.isSharedWithAI)) {
                ref
                    .read(memoryProvider.notifier)
                    .updateSharedWithAI(m.id, false);
              }
              // Revoke all shared journal entries
              for (final e in ref
                  .read(journalProvider)
                  .where((e) => e.isSharedWithAI)) {
                ref
                    .read(journalProvider.notifier)
                    .updateSharedWithAI(e.id, false);
              }
            },
            child: Text('Clear all',
                style: AppTextStyles.buttonLabel
                    .copyWith(color: AppColors.dustyRose)),
          ),
        ],
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
          border:
              Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
