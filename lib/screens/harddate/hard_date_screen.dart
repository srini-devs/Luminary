import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/grief_calendar_event.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

class HardDateScreen extends ConsumerStatefulWidget {
  /// When non-null, renders in preview/future mode (from calendar).
  final GriefCalendarEvent? previewEvent;

  const HardDateScreen({super.key, this.previewEvent});

  @override
  ConsumerState<HardDateScreen> createState() => _HardDateScreenState();
}

class _HardDateScreenState extends ConsumerState<HardDateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _justBeHereMode = false;
  bool _tilesVisible = true;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _glowAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.08)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
    ]).animate(_glowCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reduceMotion =
          MediaQuery.of(context).disableAnimations ||
              (ref.read(userProfileProvider)?.reducedMotion ?? false);
      if (!reduceMotion) _glowCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _enterJustBeHere() {
    setState(() {
      _justBeHereMode = true;
      _tilesVisible = false;
    });
  }

  void _restoreTiles() {
    if (!_justBeHereMode) return;
    setState(() {
      _justBeHereMode = false;
      _tilesVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(lossProfileProvider);
    final todaysEvent = ref.watch(todaysHardDateProvider);
    final event = widget.previewEvent ?? todaysEvent;
    final name = profile?.deceasedName ?? 'them';
    final isPreview = widget.previewEvent != null;
    final isOneYear = event?.eventType == CalendarEventType.deathAnniversary &&
        (event?.label.contains('1st') ?? false);

    final eventLabel =
        event?.label.toUpperCase() ?? 'ANNIVERSARY';

    final aiMessage = isPreview
        ? "In the days ahead, this date will carry special weight. You don't have to face it alone — I'll be here with you."
        : isOneYear
            ? "One year. You've carried something so heavy for so long. Your grief is real, your love is real. I've been thinking about you today."
            : "Today is one of those harder days. You don't have to be strong right now. I'm here with you, holding this with you.";

    return GestureDetector(
      onTap: _justBeHereMode ? _restoreTiles : null,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0F2E), Color(0xFF0D0A1A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Close button (preview mode only)
                if (isPreview)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                      child: Semantics(
                        label: 'Close preview',
                        button: true,
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // ── Candle area (flex 2) ──────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _glowAnim.value,
                          child: child,
                        ),
                        child: Semantics(
                          label: 'Luminary candle',
                          excludeSemantics: true,
                          child: CandleIcon(
                            size: isOneYear ? 96 : 80,
                            flameColor: AppColors.softPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: AppTextStyles.displayH1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (isOneYear) ...[
                        const SizedBox(height: 6),
                        Text(
                          'One year. You made it.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.softPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        isPreview
                            ? 'UPCOMING: $eventLabel'
                            : eventLabel,
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: AppColors.softPurple,
                          fontSize: 14,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── AI message (flex 1) ───────────────────────────────────
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Center(
                      child: Semantics(
                        label: 'Luminary said: $aiMessage',
                        child: Text(
                          aiMessage,
                          style: AppTextStyles.bodyLight.copyWith(
                            color: Colors.white.withAlpha(204),
                            height: 1.7,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Action tiles (flex 2) ─────────────────────────────────
                Expanded(
                  flex: 2,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _tilesVisible ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ActionTile(
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Talk to me',
                                  accent: AppColors.softPurple,
                                  onTap: () => context.go('/home/companion'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionTile(
                                  icon: Icons.edit_note_outlined,
                                  label: 'Write in journal',
                                  accent: AppColors.warmAmber,
                                  onTap: () => context.push(
                                      '/home/journal/prompted'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionTile(
                                  icon: Icons.people_outline,
                                  label: 'Find community',
                                  accent: AppColors.sageGreen,
                                  onTap: () => context.go('/home/community'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionTile(
                                  icon: Icons.local_fire_department_outlined,
                                  label: 'Just be here',
                                  accent: const Color(0xFF888888),
                                  isGhost: true,
                                  onTap: _enterJustBeHere,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool isGhost;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isGhost
                ? Colors.transparent
                : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isGhost
                  ? const Color(0xFF3A3A3C)
                  : accent.withAlpha(120),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: isGhost ? const Color(0xFF888888) : accent),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isGhost
                      ? const Color(0xFF888888)
                      : Colors.white.withAlpha(230),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
