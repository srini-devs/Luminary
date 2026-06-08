import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/loss_profile.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/luminary_card.dart';
import '../../widgets/luminary_chip.dart';
import '../../widgets/section_header.dart';

class LossDatesScreen extends ConsumerStatefulWidget {
  const LossDatesScreen({super.key});

  @override
  ConsumerState<LossDatesScreen> createState() => _LossDatesScreenState();
}

class _LossDatesScreenState extends ConsumerState<LossDatesScreen> {
  DateTime? _dateOfDeath;
  DateTime? _dateOfBirth;
  final Set<HolidayType> _selectedHolidays = {};
  String? _dateError;

  static const _holidayOptions = [
    (HolidayType.christmas, 'Christmas'),
    (HolidayType.mothersDay, "Mother's Day"),
    (HolidayType.fathersDay, "Father's Day"),
    (HolidayType.easter, 'Easter'),
    (HolidayType.thanksgiving, 'Thanksgiving'),
    (HolidayType.newYear, "New Year's"),
    (HolidayType.diwali, 'Diwali'),
    (HolidayType.eid, 'Eid'),
  ];

  final _fmt = DateFormat('d MMMM yyyy');

  Future<void> _pickDateOfDeath() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfDeath ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.warmAmber),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (picked.isAfter(DateTime.now())) {
      setState(() => _dateError = 'The date entered is in the future — please check and try again.');
      return;
    }
    setState(() {
      _dateOfDeath = picked;
      _dateError = null;
    });
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1950),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.warmAmber),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _continue() {
    if (_dateOfDeath == null) {
      setState(() => _dateError = 'Please select the date of passing');
      return;
    }
    final existing = ref.read(lossProfileProvider);
    if (existing == null) return;
    final yearsAgo = DateTime.now().difference(_dateOfDeath!).inDays / 365.0;
    final updated = existing.copyWith(
      dateOfDeath: _dateOfDeath,
      dateOfBirth: _dateOfBirth,
      trackedHolidays: _selectedHolidays.toList(),
      isLongTermGrief: yearsAgo >= 10,
    );
    ref.read(lossProfileProvider.notifier).saveLossProfile(updated);
    // Fire-and-forget: persist step in background, navigate immediately
    ref.read(lossProfileProvider.notifier).saveOnboardingStep('4');
    _saveDatesKeys(
      dateOfDeath: _dateOfDeath!,
      dateOfBirth: _dateOfBirth,
      holidays: _selectedHolidays,
    );
    context.go('/onboarding/type');
  }

  Future<void> _saveDatesKeys({
    required DateTime dateOfDeath,
    DateTime? dateOfBirth,
    required Set<HolidayType> holidays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_of_death', dateOfDeath.toIso8601String());
    if (dateOfBirth != null) {
      await prefs.setString('date_of_birth', dateOfBirth.toIso8601String());
    } else {
      await prefs.remove('date_of_birth');
    }
    await prefs.setString(
      'tracked_holidays',
      jsonEncode(holidays.map((h) => h.name).toList()),
    );
  }

  void _skipDates() {
    final existing = ref.read(lossProfileProvider);
    if (existing == null) return;
    ref.read(lossProfileProvider.notifier).saveLossProfile(existing);
    // Fire-and-forget
    ref.read(lossProfileProvider.notifier).saveOnboardingStep('4');
    context.go('/onboarding/type');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? '[name]';

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
                        onTap: () => context.go('/onboarding/who'),
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
                      _ProgressDots(activeIndex: 1),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('The dates\nthat matter.', style: AppTextStyles.displayH1),
                  const SizedBox(height: 8),
                  Text(
                    'Luminary will gently remember these with you.',
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
                    const SectionHeader('DATE OF PASSING', padding: EdgeInsets.fromLTRB(2, 0, 2, 4)),
                    LuminaryCard(
                      onTap: _pickDateOfDeath,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dateOfDeath != null
                                      ? _fmt.format(_dateOfDeath!)
                                      : 'Select date',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _dateOfDeath != null
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                if (_dateOfDeath != null)
                                  Text('Date of passing', style: AppTextStyles.caption),
                              ],
                            ),
                            Text(
                              _dateOfDeath != null ? 'Change ›' : '+',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _dateOfDeath != null
                                    ? AppColors.warmAmber
                                    : AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_dateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          _dateError!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.dustyRose),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SectionHeader("$name's BIRTHDAY — OPTIONAL"),
                    LuminaryCard(
                      onTap: _pickDateOfBirth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateOfBirth != null
                                  ? _fmt.format(_dateOfBirth!)
                                  : 'Select date',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _dateOfBirth != null
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                                fontWeight: _dateOfBirth != null ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            Text(
                              '+',
                              style: TextStyle(fontSize: 18, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SectionHeader('FIRST HOLIDAYS TO REMEMBER $name ON'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _holidayOptions.map((h) {
                        return LuminaryChip(
                          label: h.$2,
                          isSelected: _selectedHolidays.contains(h.$1),
                          onTap: () => setState(() {
                            if (_selectedHolidays.contains(h.$1)) {
                              _selectedHolidays.remove(h.$1);
                            } else {
                              _selectedHolidays.add(h.$1);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    LuminaryButton(label: 'Continue', onTap: _continue),
                    const SizedBox(height: 10),
                    LuminaryButton(
                      label: "I'll add dates later",
                      onTap: _skipDates,
                      style: LuminaryButtonStyle.ghost,
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
