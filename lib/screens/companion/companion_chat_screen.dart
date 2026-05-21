import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/ai_message.dart';
import '../../providers/companion_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

const _crisisKeywords = [
  'end my life',
  'kill myself',
  'suicide',
  "don't want to be here",
  "dont want to be here",
  "can't go on",
  "cant go on",
  'hurt myself',
  'self harm',
  'ending it all',
  'no reason to live',
];

class CompanionChatScreen extends ConsumerStatefulWidget {
  const CompanionChatScreen({super.key});

  @override
  ConsumerState<CompanionChatScreen> createState() =>
      _CompanionChatScreenState();
}

class _CompanionChatScreenState
    extends ConsumerState<CompanionChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openConversation());
  }

  @override
  void dispose() {
    ref.read(companionProvider.notifier).saveSessionSummary();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openConversation() async {
    setState(() => _isTyping = true);
    await ref.read(companionProvider.notifier).openConversation();
    if (!mounted) return;
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // TC-11: crisis keyword check — intercept before API call
    final lower = text.toLowerCase();
    if (_crisisKeywords.any((kw) => lower.contains(kw))) {
      _inputController.clear();
      _showCrisisSheet();
      return;
    }

    _inputController.clear();

    // Offline mode — return pre-loaded message, skip API
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      final profile = ref.read(lossProfileProvider);
      final isHardDate = ref.read(isHardDateTodayProvider);
      final messages = ref.read(companionProvider);
      final offlineMsg = CompanionNotifier.offlineMessage(
        profile?.deceasedName ?? 'them',
        isHardDate,
        messages.length,
      );
      final now = DateTime.now();
      ref.read(companionProvider.notifier).appendMessages([
        AiMessage(
          id: '${now.millisecondsSinceEpoch}_u',
          role: AiMessageRole.user,
          content: text,
          timestamp: now,
        ),
        AiMessage(
          id: '${now.millisecondsSinceEpoch}_a',
          role: AiMessageRole.assistant,
          content: offlineMsg,
          timestamp: now,
        ),
      ]);
      if (mounted) _scrollToBottom();
      return;
    }

    setState(() => _isTyping = true);
    await ref.read(companionProvider.notifier).sendMessage(text);
    if (!mounted) return;
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCrisisSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CrisisSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(lossProfileProvider);
    final isHardDate = ref.watch(isHardDateTodayProvider);
    final todaysHardDate = ref.watch(todaysHardDateProvider);
    final messages = ref.watch(companionProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final name = profile?.deceasedName ?? 'them';
    final reduceMotion = MediaQuery.of(context).disableAnimations;

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
                  _CircleButton(
                    onTap: () => context.go('/home/dashboard'),
                    child: const Text(
                      '‹',
                      style: TextStyle(
                          fontSize: 22, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "$name's Companion",
                      style: AppTextStyles.screenTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _CircleButton(
                    onTap: _showCrisisSheet,
                    child: const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Offline banner
            if (isOffline)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B3B4F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'You\'re offline — responses are from saved messages',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            // Hard date context bar
            if (isHardDate && todaysHardDate != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.purpleTint,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(
                        color: AppColors.softPurple, width: 4),
                  ),
                ),
                child: Text(
                  'Today is ${todaysHardDate.label}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.softPurple,
                    fontSize: 13,
                  ),
                ),
              ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == messages.length) {
                    return _TypingBubble(reduceMotion: reduceMotion);
                  }
                  final msg = messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: msg.role == AiMessageRole.user
                        ? _UserBubble(content: msg.content)
                        : _AiBubble(content: msg.content),
                  );
                },
              ),
            ),
            // Input bar
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgGray,
                border: Border(
                    top: BorderSide(color: AppColors.divider, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.divider, width: 1.5),
                          ),
                          child: TextField(
                            controller: _inputController,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Write to Luminary…',
                              hintStyle: AppTextStyles.bodyMedium
                                  .copyWith(
                                      color: AppColors.textTertiary),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _send();
                        },
                        child: Container(
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
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      _showCrisisSheet();
                    },
                    child: Container(
                      height: 38,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.divider, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'This is too much right now',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.dustyRose,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

class _AiBubble extends StatelessWidget {
  final String content;
  const _AiBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Text(content, style: AppTextStyles.bodyLight),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String content;
  const _UserBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(content,
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white)),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final bool reduceMotion;
  const _TypingBubble({required this.reduceMotion});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (!widget.reduceMotion) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                final opacity = widget.reduceMotion
                    ? 0.6
                    : (0.3 +
                        0.7 *
                            ((_ctrl.value + i * 0.33) % 1.0));
                return Container(
                  margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary
                        .withAlpha((opacity * 255).round()),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleButton({required this.child, this.onTap});

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

class _CrisisSheet extends StatelessWidget {
  const _CrisisSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.of(context).padding.bottom + 80),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CandleIcon(size: 32),
            const SizedBox(height: 16),
            Text("You don't have to be alone.",
                style: AppTextStyles.screenTitle),
            const SizedBox(height: 8),
            Text(
              'If you\'re in crisis, please reach out. Trained counsellors are available now.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _CrisisLine(
                name: '988 Suicide & Crisis Lifeline',
                detail: 'Call or text 988 (US)'),
            _CrisisLine(
                name: 'Crisis Text Line',
                detail: 'Text HOME to 741741'),
            _CrisisLine(
                name: 'Samaritans',
                detail: 'Call 116 123 (UK)'),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.divider, width: 1.5),
                ),
                child: Center(
                  child: Text('Close',
                      style: AppTextStyles.buttonLabel
                          .copyWith(color: AppColors.textTertiary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrisisLine extends StatelessWidget {
  final String name;
  final String detail;
  const _CrisisLine({required this.name, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined,
              size: 16, color: AppColors.softPurple),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(detail, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
