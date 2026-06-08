import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/checkin_entry.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/companion_provider.dart';
import '../../providers/dev_index_provider.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/section_header.dart';

const _uuid = Uuid();

// Emotions that use green chip when selected
const _positiveEmotions = {
  EmotionType.grateful,
  EmotionType.peaceful,
  EmotionType.hopeful,
};

const _emotionLabels = {
  EmotionType.heavy: 'Heavy',
  EmotionType.missing: 'Missing them',
  EmotionType.angry: 'Angry',
  EmotionType.numb: 'Numb',
  EmotionType.grateful: 'Grateful',
  EmotionType.lonely: 'Lonely',
  EmotionType.peaceful: 'Peaceful',
  EmotionType.exhausted: 'Exhausted',
  EmotionType.hopeful: 'Hopeful',
  EmotionType.sad: 'Sad',
  EmotionType.confused: 'Confused',
  EmotionType.disconnected: 'Disconnected',
};

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  double _wave = 5.0;
  final Set<EmotionType> _emotions = {};
  bool _noteExpanded = false;
  final _noteController = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final wave = _wave.round();
    final entry = CheckinEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      waveIntensity: wave,
      emotions: _emotions.toList(),
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      isHardDate: ref.read(isHardDateTodayProvider),
    );
    ref.read(checkinProvider.notifier).saveCheckin(entry);

    if (wave >= 8) {
      ref.read(companionProvider.notifier).setHighIntensityPending(true);
    }

    ref.read(notificationProvider.notifier).cancelCheckinReminder();

    setState(() => _saved = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final streak = ref.read(checkinProvider.notifier).streakDays;
      if (streak == 7) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("7-day streak — you're showing up for yourself."),
            backgroundColor: AppColors.sageGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHardDate = ref.watch(isHardDateTodayProvider);
    final todaysHardDate = ref.watch(todaysHardDateProvider);
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';
    final now = DateTime.now();
    final dateFmt = DateFormat('EEEE, d MMMM');
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final devState = ref.watch(devStateProvider);

    // Dev: show confirmation/saved state
    if (_saved || devState == 'confirmation' || devState == 'streak7') {
      return _SavedConfirmation(
        wave: devState == 'confirmation' ? 6 : _wave.round(),
        emotions: devState != null && !_saved
            ? [EmotionType.sad, EmotionType.missing]
            : _emotions.toList(),
        name: name,
        streakDays: devState == 'streak7' ? 7 : null,
      );
    }

    // Dev: streak state - pre-populate with streak info shown in header
    final showStreakBadge = devState == 'streak' || devState == 'streak7';

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                        child: Text('✕',
                            style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'TODAY',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warmAmber,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          dateFmt.format(now),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (isHardDate && todaysHardDate != null)
                          Text(
                            todaysHardDate.label,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.softPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (showStreakBadge)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sageGreen.withAlpha(30),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: AppColors.sageGreen, width: 1.5),
                            ),
                            child: Text(
                              '🔥 ${devState == 'streak7' ? '7' : '3'}-day streak',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.sageGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wave slider labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calm',
                            style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600)),
                        Text('Overwhelming',
                            style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Gradient track + slider
                    SizedBox(
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(100),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7AB893),
                                    Color(0xFFE8A87C),
                                    Color(0xFFE07070),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: AppColors.warmAmber,
                              thumbShape:
                                  const RoundSliderThumbShape(
                                enabledThumbRadius: 14,
                              ),
                              overlayShape:
                                  SliderComponentShape.noOverlay,
                              trackHeight: 8,
                            ),
                            child: Slider(
                              value: _wave,
                              min: 1,
                              max: 10,
                              divisions: reduceMotion ? null : 9,
                              onChanged: (v) {
                                if (v.round() != _wave.round()) {
                                  HapticFeedback.selectionClick();
                                }
                                setState(() => _wave = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      child: Center(
                        child: Text(
                          '${_wave.round()} / 10',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    // Emotions
                    SectionHeader(
                        'HOW ARE YOU FEELING?',
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 12)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EmotionType.values.map((emotion) {
                        final isSelected =
                            _emotions.contains(emotion);
                        final isPositive =
                            _positiveEmotions.contains(emotion);
                        final selectedColor = isPositive
                            ? AppColors.sageGreen
                            : AppColors.softPurple;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _emotions.remove(emotion);
                              } else {
                                _emotions.add(emotion);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bgWhite,
                              borderRadius:
                                  BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : AppColors.divider,
                                width: isSelected ? 2.5 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: selectedColor,
                                        offset: const Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _emotionLabels[emotion] ?? emotion.name,
                              style: AppTextStyles.chipLabel.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Optional note
                    GestureDetector(
                      onTap: () =>
                          setState(() => _noteExpanded = !_noteExpanded),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.cardRadius),
                          border: Border.all(
                              color: AppColors.cardBorder, width: 2),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Anything else? (optional)',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                            color:
                                                AppColors.textTertiary),
                                  ),
                                  Text(
                                    _noteExpanded ? '↑' : '↓',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                            if (_noteExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 14),
                                child: TextField(
                                  controller: _noteController,
                                  maxLines: 4,
                                  autofocus: true,
                                  style: AppTextStyles.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Write something…',
                                    hintStyle: AppTextStyles.bodyMedium
                                        .copyWith(
                                            color:
                                                AppColors.textTertiary),
                                    border: InputBorder.none,
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
            ),
            // Fixed save button
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgGray,
                border: Border(
                    top: BorderSide(
                        color: AppColors.divider, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: LuminaryButton(
                label: _emotions.isEmpty ? 'Select emotions to save' : 'Save check-in',
                onTap: _emotions.isEmpty ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedConfirmation extends StatelessWidget {
  final int wave;
  final List<EmotionType> emotions;
  final String name;
  final int? streakDays;
  const _SavedConfirmation(
      {required this.wave,
      required this.emotions,
      required this.name,
      this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.sageGreen),
                const SizedBox(height: 20),
                Text('Check-in saved.',
                    style: AppTextStyles.displayH1),
                const SizedBox(height: 8),
                Text(
                  'Wave intensity: $wave / 10',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary),
                ),
                if (emotions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    emotions
                        .map((e) =>
                            _emotionLabels[e] ?? e.name)
                        .join(', '),
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (wave >= 8) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.purpleTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Your companion noticed. I'll check in with you shortly.",
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.softPurple),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (streakDays != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.sageGreen, width: 1.5),
                    ),
                    child: Text(
                      '🔥 $streakDays-day streak — you\'re showing up for yourself.',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.sageGreen),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

