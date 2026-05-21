import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/memory_entry.dart';
import '../../providers/memory_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class MemoryViewScreen extends ConsumerStatefulWidget {
  final MemoryEntry memory;
  const MemoryViewScreen({super.key, required this.memory});

  @override
  ConsumerState<MemoryViewScreen> createState() =>
      _MemoryViewScreenState();
}

class _MemoryViewScreenState
    extends ConsumerState<MemoryViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_scaleCtrl);

    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((ps) {
      if (mounted) setState(() => _isPlaying = ps.playing);
    });
    // TODO(backend): Load real voice note URL from storage
    // if (widget.memory.voiceNoteUrl != null &&
    //     !widget.memory.voiceNoteUrl!.startsWith('mock://')) {
    //   _audioPlayer.setUrl(widget.memory.voiceNoteUrl!);
    // }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // TODO(backend): _audioPlayer.play() with real URL — mock simulates playback
      setState(() => _isPlaying = true);
      await Future.delayed(const Duration(seconds: 42));
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _onRemember() {
    HapticFeedback.mediumImpact();
    final reduceMotion =
        MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      _scaleCtrl.forward(from: 0);
    }
  }

  void _confirmDelete() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(sheetCtx).padding.bottom + 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete memory?',
                style: AppTextStyles.screenTitle
                    .copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'This cannot be undone.',
              style: AppTextStyles.bodyLight,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                ref
                    .read(memoryProvider.notifier)
                    .removeMemory(widget.memory.id);
                Navigator.of(context).pop();
                context.pop();
              },
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.dustyRose,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.buttonRadius),
                  border: Border.all(
                      color: AppColors.dustyRose, width: 2),
                ),
                child: Text('Delete',
                    style: AppTextStyles.buttonLabel
                        .copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.buttonRadius),
                  border: Border.all(
                      color: AppColors.divider, width: 2),
                ),
                child: Text('Cancel',
                    style: AppTextStyles.buttonLabel.copyWith(
                        color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final dateFmt = DateFormat('d MMMM yyyy');

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
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text(m.title ?? 'Memory',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  _CircleBtn(
                    onTap: _confirmDelete,
                    child: const Icon(Icons.delete_outline,
                        size: 18,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // AI sharing badge
                  if (m.isSharedWithAI) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.purpleTint,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.softPurple, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 14,
                              color: AppColors.softPurple),
                          const SizedBox(width: 6),
                          Text(
                            'Shared with companion',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.softPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Main content card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.cardRadius),
                      border: Border.all(
                          color: AppColors.cardBorder, width: 2),
                    ),
                    child: _buildContent(m),
                  ),
                  const SizedBox(height: 14),
                  // Date caption
                  Text(
                    'Added ${dateFmt.format(m.addedAt)}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 28),
                  // Remember button
                  AnimatedBuilder(
                    animation: _scaleAnim,
                    builder: (context, child) => Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    ),
                    child: GestureDetector(
                      onTap: _onRemember,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.buttonRadius),
                          border: Border.all(
                              color: AppColors.warmAmber, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.warmAmber,
                              offset: AppDimensions.neoShadowOffset,
                              blurRadius: AppDimensions.neoShadowBlur,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border,
                                size: 18,
                                color: AppColors.warmAmber),
                            const SizedBox(width: 8),
                            Text('Remember',
                                style: AppTextStyles.buttonLabel
                                    .copyWith(
                                        color: AppColors.warmAmber)),
                          ],
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

  Widget _buildContent(MemoryEntry m) {
    if (m.voiceNoteUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic_outlined,
                    size: 20,
                    color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Voice note',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.warmAmber,
                    AppColors.softPurple,
                    AppColors.sageGreen,
                    AppColors.warmAmber,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('0:00 / 0:42',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      );
    }

    if (m.textContent != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '"${m.textContent}"',
          style: AppTextStyles.bodyLarge.copyWith(
              height: 1.75,
              fontSize: 16,
              fontWeight: FontWeight.w300),
        ),
      );
    }

    // Photo placeholder
    return Column(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            color: AppColors.amberTint,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.cardRadius - 1),
              topRight:
                  Radius.circular(AppDimensions.cardRadius - 1),
            ),
          ),
          child: const Center(
            child: Text('🌷', style: TextStyle(fontSize: 60)),
          ),
        ),
        if (m.title != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(m.title!,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
      ],
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
