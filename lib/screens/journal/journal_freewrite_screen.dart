import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';

const _fwuuid = Uuid();

class JournalFreewiteScreen extends ConsumerStatefulWidget {
  final JournalEntry? existingEntry;
  const JournalFreewiteScreen({super.key, this.existingEntry});

  @override
  ConsumerState<JournalFreewiteScreen> createState() =>
      _JournalFreewiteScreenState();
}

class _JournalFreewiteScreenState
    extends ConsumerState<JournalFreewiteScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _controller.text = widget.existingEntry!.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (_isEditing) {
      final updated = widget.existingEntry!.copyWith(
        title: _firstLine(text),
        content: text,
      );
      ref.read(journalProvider.notifier).updateEntry(updated);
    } else {
      final entry = JournalEntry(
        id: _fwuuid.v4(),
        date: DateTime.now(),
        title: _firstLine(text),
        content: text,
        waveIntensityAtTime: 5,
        intensityLevel: JournalIntensityLevel.gentle,
      );
      ref.read(journalProvider.notifier).addEntry(entry);
    }
    if (mounted) context.pop();
  }

  String _firstLine(String text) {
    final words = text.trim().split(' ');
    return words.take(6).join(' ') + (words.length > 6 ? '…' : '');
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final canSave = wordCount > 0 && !_isSaving;
    final dateFmt = DateFormat(
            'd MMMM yyyy · h:mm a')
        .format(DateTime.now());

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
                    child: Text(_isEditing ? 'Edit Entry' : 'New Entry',
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
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 100),
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
                    // Free write card
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amberTint,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: const Border(
                          left: BorderSide(
                              color: AppColors.warmAmber, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FREE WRITE',
                            style: AppTextStyles.sectionLabel
                                .copyWith(color: AppColors.amberDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This is your space. Write whatever you need to.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(
                                    fontWeight: FontWeight.w300,
                                    height: 1.7),
                          ),
                        ],
                      ),
                    ),
                    // Text area
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 320),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.warmAmber,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.warmAmber,
                            offset: AppDimensions.neoShadowOffset,
                            blurRadius: AppDimensions.neoShadowBlur,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        autofocus: true,
                        style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.7),
                        decoration: InputDecoration(
                          hintText:
                              'Start writing — or just be here for a moment…',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(
                                  color: AppColors.textTertiary),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    // Word count
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
                label: _isEditing ? 'Save changes' : 'Save entry',
                onTap: canSave ? _save : null,
                isLoading: _isSaving,
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
