import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';

const _puuid = Uuid();

// TODO(backend): Generate prompt from Claude API using loss profile context
const _mockPrompts = [
  'What\'s one thing you\'d want them to know about this past week?',
  'Is there a small object near you that belonged to them or reminds you of them? What does it hold for you today?',
  'What\'s a sound, smell, or place that brings them closest to you right now?',
  'If you could tell them one thing today, what would it be?',
];

class JournalPromptedScreen extends ConsumerStatefulWidget {
  const JournalPromptedScreen({super.key});

  @override
  ConsumerState<JournalPromptedScreen> createState() =>
      _JournalPromptedScreenState();
}

class _JournalPromptedScreenState
    extends ConsumerState<JournalPromptedScreen> {
  final _controller = TextEditingController();
  final String _prompt =
      _mockPrompts[DateTime.now().day % _mockPrompts.length];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final entry = JournalEntry(
      id: _puuid.v4(),
      date: DateTime.now(),
      title: _firstLine(text),
      content: text,
      promptUsed: _prompt,
      waveIntensityAtTime: 5,
      intensityLevel: JournalIntensityLevel.moderate,
    );
    ref.read(journalProvider.notifier).addEntry(entry);
    context.pop();
  }

  String _firstLine(String text) {
    final words = text.trim().split(' ');
    return words.take(6).join(' ') + (words.length > 6 ? '…' : '');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';
    final wordCount = _controller.text.trim().isEmpty
        ? 0
        : _controller.text.trim().split(RegExp(r'\s+')).length;
    final dateFmt = DateFormat('d MMMM yyyy').format(DateTime.now());
    final canSave = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      resizeToAvoidBottomInset: true,
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
                    child: Text('New Entry',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  _CircleBtn(
                    onTap: () => context.pop(),
                    child: const Text('✕',
                        style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        dateFmt.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warmAmber,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Prompt card
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LUMINARY PROMPT',
                            style: AppTextStyles.aiAccent.copyWith(
                                fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _prompt.replaceAll('them', name),
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w300,
                                height: 1.7),
                          ),
                        ],
                      ),
                    ),
                    // Text area
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 280),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 2),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        autofocus: true,
                        style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.7),
                        decoration: InputDecoration(
                          hintText: 'Begin writing…',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    // Word count + privacy row
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Private',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(
                                        fontWeight: FontWeight.w600)),
                            Text(
                              '$wordCount words',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Save button
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgGray,
                border: Border(
                    top: BorderSide(
                        color: AppColors.divider, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: LuminaryButton(
                label: 'Save entry',
                onTap: canSave ? _save : null,
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
