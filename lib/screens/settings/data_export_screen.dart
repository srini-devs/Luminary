import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/section_header.dart';

enum _ExportFormat { pdf, json, plainText }

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  int _rangeIdx = 0; // 0=All time, 1=Last 90 days, 2=Custom
  _ExportFormat _format = _ExportFormat.pdf;
  bool _isExporting = false;

  Future<void> _export() async {
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _isExporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your data export is being prepared. You\'ll be notified when it\'s ready.'),
        backgroundColor: AppColors.sageGreen,
        duration: Duration(seconds: 3),
      ),
    );
    // TODO(backend): Trigger Supabase data export and return download link
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
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
                    child: Text('Export my data',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  // Info card
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.amberTint,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.cardRadius),
                      border: const Border(
                          left: BorderSide(
                              color: AppColors.warmAmber, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What\'s included',
                            style: AppTextStyles.sectionLabel.copyWith(
                                color: AppColors.amberDark, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          'Your data belongs to you. Export everything Luminary has stored — your journal, check-ins, memories, wave data, and conversation history.',
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w300, height: 1.7),
                        ),
                      ],
                    ),
                  ),

                  // Date range
                  SectionHeader('DATE RANGE',
                      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        _RangeTab(label: 'All time', selected: _rangeIdx == 0,
                            onTap: () { HapticFeedback.selectionClick(); setState(() => _rangeIdx = 0); }),
                        _RangeTab(label: 'Last 90 days', selected: _rangeIdx == 1,
                            onTap: () { HapticFeedback.selectionClick(); setState(() => _rangeIdx = 1); }),
                        _RangeTab(label: 'Custom', selected: _rangeIdx == 2,
                            onTap: () { HapticFeedback.selectionClick(); setState(() => _rangeIdx = 2); }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Format
                  SectionHeader('FORMAT',
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.cardRadius),
                      border:
                          Border.all(color: AppColors.cardBorder, width: 2),
                    ),
                    child: Column(
                      children: [
                        _FormatRow(
                          label: 'PDF (readable)',
                          selected: _format == _ExportFormat.pdf,
                          onTap: () { HapticFeedback.selectionClick(); setState(() => _format = _ExportFormat.pdf); },
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        _FormatRow(
                          label: 'JSON (developer)',
                          selected: _format == _ExportFormat.json,
                          onTap: () { HapticFeedback.selectionClick(); setState(() => _format = _ExportFormat.json); },
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        _FormatRow(
                          label: 'Plain text',
                          selected: _format == _ExportFormat.plainText,
                          onTap: () { HapticFeedback.selectionClick(); setState(() => _format = _ExportFormat.plainText); },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  LuminaryButton(
                    label: 'Export my data',
                    onTap: _isExporting ? null : _export,
                    isLoading: _isExporting,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your data is encrypted. The export file will be password-protected.',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary, height: 1.55),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.warmAmber : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.warmAmber : AppColors.divider,
                  width: 2.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
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
