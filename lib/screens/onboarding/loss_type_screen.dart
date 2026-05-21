import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/loss_profile.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/section_header.dart';

class LossTypeScreen extends ConsumerStatefulWidget {
  const LossTypeScreen({super.key});

  @override
  ConsumerState<LossTypeScreen> createState() => _LossTypeScreenState();
}

class _LossTypeScreenState extends ConsumerState<LossTypeScreen> {
  LossType? _selectedType;

  String _timeSinceLoss(DateTime dod) {
    final diff = DateTime.now().difference(dod);
    final days = diff.inDays;
    if (days < 14) return 'About $days days ago';
    if (days < 60) return 'About ${(days / 7).round()} weeks ago';
    final months = (days / 30.5).round();
    if (months < 24) return 'About $months ${months == 1 ? 'month' : 'months'} ago';
    return 'About ${(months / 12).round()} years ago';
  }

  void _start() {
    if (_selectedType == null) return;
    final existing = ref.read(lossProfileProvider);
    if (existing == null) return;
    final updated = existing.copyWith(lossType: _selectedType);
    ref.read(lossProfileProvider.notifier).saveLossProfile(updated);
    // Fire-and-forget: mark complete in background, navigate immediately
    ref.read(lossProfileProvider.notifier).saveOnboardingComplete();
    ref.read(appStateProvider.notifier).setOnboardingComplete();
    _saveTypeKey(_selectedType!);
    context.go('/onboarding/notifications');
  }

  Future<void> _saveTypeKey(LossType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loss_type', type.name);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? '[name]';
    final dod = profile?.dateOfDeath ?? DateTime.now().subtract(const Duration(days: 30));

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/onboarding/dates'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.divider, width: 1.5),
                          ),
                          child: const Center(
                            child: Text('‹',
                                style: TextStyle(
                                    fontSize: 22,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ProgressDots(activeIndex: 2),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Help me understand\nyour grief.', style: AppTextStyles.displayH1),
                  const SizedBox(height: 8),
                  Text(
                    'This personalises your experience — it is never shared.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeCard(
                      emoji: '⚡',
                      title: 'Sudden or unexpected',
                      subtitle: 'Accident, heart attack, no warning',
                      isSelected: _selectedType == LossType.sudden,
                      onTap: () => setState(() => _selectedType = LossType.sudden),
                    ),
                    _TypeCard(
                      customIcon: const CandleIcon(size: 24),
                      title: 'After an illness or expected loss',
                      subtitle: 'Long illness, hospice, time to say goodbye',
                      isSelected: _selectedType == LossType.expected,
                      onTap: () => setState(() => _selectedType = LossType.expected),
                    ),
                    const SizedBox(height: 8),
                    SectionHeader('HOW LONG AGO DID YOU LOSE $name?'),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/onboarding/dates');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                          border: Border.all(color: AppColors.cardBorder, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _timeSinceLoss(dod),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'edit ›',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warmAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    LuminaryButton(
                      label: 'Start with Luminary →',
                      onTap: _selectedType != null ? _start : null,
                      style: LuminaryButtonStyle.primary,
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

class _TypeCard extends StatelessWidget {
  final String? emoji;
  final Widget? customIcon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    this.emoji,
    this.customIcon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.softPurple : AppColors.cardBorder,
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.softPurple,
                    offset: AppDimensions.neoShadowOffset,
                    blurRadius: AppDimensions.neoShadowBlur,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 24))
            else
              ?customIcon,
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int activeIndex;
  const _ProgressDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == activeIndex;
        return Container(
          width: isActive ? 24 : 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.warmAmber : AppColors.divider,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}
