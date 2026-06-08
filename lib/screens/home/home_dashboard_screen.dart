import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/ai_message.dart';
import '../../models/grief_calendar_event.dart';
import '../../models/user_profile.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/companion_provider.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/memory_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/hard_date_banner.dart';
import '../../widgets/luminary_card.dart';
import '../../widgets/section_header.dart';

const _kFirstVisit = 'first_visit';
const _kLastAppOpen = 'last_app_open';
const _kFirstDashboardVisit = 'first_dashboard_visit';
const _kLastHardDateShown = 'last_hard_date_shown';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _showHardDateBanner = false;
  bool _greetingVisible = false;
  bool _isWelcomeBack = false;
  String? _greetingSubtitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstLoad());
  }

  Future<void> _onFirstLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = ref.read(lossProfileProvider);
    final isHardDate = ref.read(isHardDateTodayProvider);
    final now = DateTime.now();

    // 48h hard date banner persistence
    if (isHardDate) {
      await prefs.setString(_kLastHardDateShown, now.toIso8601String());
    }
    final lastHardDateShownStr = prefs.getString(_kLastHardDateShown);
    if (lastHardDateShownStr != null) {
      final lastShown = DateTime.tryParse(lastHardDateShownStr);
      if (lastShown != null && now.difference(lastShown).inHours < 48) {
        if (mounted) setState(() => _showHardDateBanner = true);
      }
    }

    // Smart greeting logic
    final isFirstDashboardVisit =
        prefs.getString(_kFirstDashboardVisit) == null;
    String? subtitle;
    bool useWelcomeBack = false;

    if (isFirstDashboardVisit) {
      await prefs.setString(_kFirstDashboardVisit, now.toIso8601String());
      subtitle = 'Welcome to Luminary. I\'m here with you.';
    } else {
      final lastOpenStr = prefs.getString(_kLastAppOpen);
      if (lastOpenStr != null) {
        final lastOpen = DateTime.tryParse(lastOpenStr);
        if (lastOpen != null) {
          final diff = now.difference(lastOpen).inDays;
          if (diff >= 3) {
            useWelcomeBack = true;
            subtitle = "It's been a few days — I'm glad you're here.";
          } else if (diff >= 1) {
            subtitle = 'Good to see you again.';
          }
        }
      }
    }

    // First visit: send welcome companion message
    final isFirstVisit = prefs.getString(_kFirstVisit) == null;
    if (isFirstVisit && profile != null) {
      await prefs.setString(_kFirstVisit, 'true');
      ref.read(companionProvider.notifier).sendWelcomeMessage(profile);
    }

    await prefs.setString(_kLastAppOpen, now.toIso8601String());

    if (!mounted) return;
    setState(() {
      _greetingSubtitle = subtitle;
      _isWelcomeBack = useWelcomeBack;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _greetingVisible = true);
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  String _daysUntil(GriefCalendarEvent event) {
    final diff = event.date.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'in $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final profile = ref.watch(lossProfileProvider);
    final isHardDate = ref.watch(isHardDateTodayProvider);
    final todaysHardDate = ref.watch(todaysHardDateProvider);
    final nextHardDate = ref.watch(nextUpcomingHardDateProvider);
    final isTodayCheckedIn = ref.watch(isTodayCheckedInProvider);
    final messages = ref.watch(companionProvider);
    final journal = ref.watch(journalProvider);
    final memories = ref.watch(memoryProvider);

    final firstName = (user?.displayName ?? 'there').split(' ').first;
    final name = profile?.deceasedName ?? 'them';
    final lastAiMsg = messages
        .where((m) => m.role == AiMessageRole.assistant)
        .fold<AiMessage?>(null, (_, m) => m);
    final aiPreview = lastAiMsg?.content ??
        "I've been thinking about you today. How are you holding up right now?";
    final lastJournal = journal.isNotEmpty ? journal.first : null;
    final memoryCount = memories.length;
    final lastMemory = memories.isNotEmpty ? memories.first : null;
    final fmt = DateFormat('d MMM');

    // Trial expiry banner
    bool showTrialBanner = false;
    bool trialExpiringSoon = false;
    if (user != null &&
        user.subscriptionStatus == SubscriptionStatus.trial &&
        user.trialEndDate != null) {
      final daysLeft =
          user.trialEndDate!.difference(DateTime.now()).inDays;
      if (daysLeft >= 0 && daysLeft <= 3) {
        showTrialBanner = true;
        trialExpiringSoon = daysLeft <= 1;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 48h hard date banner
                  if (_showHardDateBanner)
                    HardDateBanner(
                      title: isHardDate && todaysHardDate != null
                          ? '${todaysHardDate.label} is today'
                          : 'You recently had a significant day',
                      subtitle: 'Tap to open your companion',
                      onTap: () => context.go('/home/companion'),
                    ),
                  // Trial expiry banner
                  if (showTrialBanner)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/paywall?dismissible=true');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: trialExpiringSoon
                              ? AppColors.dustyRose.withAlpha(30)
                              : AppColors.amberTint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border(
                            left: BorderSide(
                              color: trialExpiringSoon
                                  ? AppColors.dustyRose
                                  : AppColors.warmAmber,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                trialExpiringSoon
                                    ? 'Your trial ends very soon — upgrade to keep Luminary'
                                    : 'Your free trial is ending in a few days',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'Upgrade →',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warmAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AnimatedOpacity(
                    opacity: _greetingVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isWelcomeBack
                              ? 'Welcome back, $firstName.'
                              : '${_timeGreeting()}, $firstName.',
                          style: AppTextStyles.displayH1,
                        ),
                        if (_greetingSubtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _greetingSubtitle!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                children: [
                  // Companion card
                  const SectionHeader('YOUR COMPANION'),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go('/home/companion');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.cardRadius),
                        border: Border.all(
                            color: AppColors.softPurple, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.softPurple,
                            offset: AppDimensions.neoShadowOffset,
                            blurRadius: AppDimensions.neoShadowBlur,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius - 1),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 21, 16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CandleIcon(size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$name's Companion".toUpperCase(),
                                        style: AppTextStyles.sectionLabel
                                            .copyWith(
                                          color: AppColors.softPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(aiPreview,
                                      style: AppTextStyles.bodyLight),
                                  const SizedBox(height: 8),
                                  Text('Talk to me →',
                                      style: AppTextStyles.aiAccent),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: AppDimensions.colorStripWidth,
                                color: AppColors.softPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Check-in card
                  const SectionHeader("TODAY'S CHECK-IN"),
                  LuminaryCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/checkin');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTodayCheckedIn
                                      ? 'Check-in complete'
                                      : 'How are you today?',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isTodayCheckedIn
                                      ? 'Well done for checking in today'
                                      : 'Not checked in yet today',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          isTodayCheckedIn
                              ? Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.sageGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 22),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.warmAmber,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.amberDark,
                                        offset: Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '→',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  // Coming up
                  if (nextHardDate != null) ...[
                    const SectionHeader('COMING UP'),
                    LuminaryCard(
                      rightStripColor: const Color(0xFF3B82F6),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/calendar');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.amberTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  const Center(child: CandleIcon(size: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nextHardDate.label,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_daysUntil(nextHardDate)} — ${fmt.format(nextHardDate.date)}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '›',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Journal
                  const SectionHeader('YOUR JOURNAL'),
                  LuminaryCard(
                    rightStripColor: AppColors.sageGreen,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go('/home/journal');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.amberTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('📖',
                                  style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last entry',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastJournal != null
                                      ? '${_relativeDate(lastJournal.date)} · "${lastJournal.title}"'
                                      : 'No entries yet — start writing',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '›',
                            style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Memory space
                  SectionHeader("$name'S SPACE"),
                  LuminaryCard(
                    rightStripColor: AppColors.warmAmber,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/home/memory');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.amberTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('📸',
                                  style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$name's Space",
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  memoryCount > 0
                                      ? '$memoryCount ${memoryCount == 1 ? 'memory' : 'memories'} · Last added ${lastMemory != null ? _relativeDate(lastMemory.addedAt) : ''}'
                                      : 'No memories yet — add the first one',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '›',
                            style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
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
