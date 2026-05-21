import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/community_post.dart';
import '../../models/loss_profile.dart';
import '../../providers/community_provider.dart';
import '../../providers/dev_index_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';

const _cpuuid = Uuid();

const _postTypes = [
  (PostType.sharing, 'Share'),
  (PostType.seekingSupport, 'Seek support'),
  (PostType.memoryShare, 'Memory'),
  (PostType.question, 'Question'),
];

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends ConsumerState<CreatePostScreen> {
  PostType _selectedType = PostType.sharing;
  bool _isAnonymous = true;
  final _controller = TextEditingController();
  bool _isPosting = false;
  bool _isPosted = false;
  String? _postedContext;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    HapticFeedback.mediumImpact();
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;
    final profile = ref.read(lossProfileProvider);
    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final post = CommunityPost(
      id: _cpuuid.v4(),
      authorDisplayName: _isAnonymous ? null : 'You',
      isAnonymous: _isAnonymous,
      content: text,
      postType: _selectedType,
      lossType: profile?.relationship ?? RelationshipType.other,
      weeksOutFromLoss: 0,
      createdAt: DateTime.now(),
    );
    ref.read(communityProvider.notifier).addPost(post);
    final relName = _relLabel(profile?.relationship);
    final weeks = profile != null
        ? DateTime.now().difference(profile.dateOfDeath).inDays ~/ 7
        : 0;
    final timeRange = _timeRangeLabel(weeks);
    final ctx = '${_isAnonymous ? 'anonymously' : 'as ${post.authorDisplayName}'} to the $relName community at $timeRange';
    if (mounted) setState(() { _isPosted = true; _postedContext = ctx; });
  }

  String _relLabel(RelationshipType? rel) {
    return switch (rel) {
      RelationshipType.parent => 'parent loss',
      RelationshipType.spouse => 'spouse loss',
      RelationshipType.child => 'child loss',
      RelationshipType.sibling => 'sibling loss',
      RelationshipType.friend => 'friend loss',
      RelationshipType.pet => 'pet loss',
      _ => 'community',
    };
  }

  String _timeRangeLabel(int weeks) {
    if (weeks < 13) return '0–3 months';
    if (weeks < 26) return '3–6 months';
    if (weeks < 52) return '6–12 months';
    if (weeks < 104) return '1–2 years';
    return '2+ years';
  }

  @override
  Widget build(BuildContext context) {
    final devState = ref.watch(devStateProvider);
    if (_isPosted || devState == 'success') {
      return _PostSuccessView(
          context: _postedContext ?? 'anonymously to the community');
    }

    final text = _controller.text;
    final wordCount =
        text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final canPost = wordCount > 0 && !_isPosting;

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
                    child: Text('Share with community',
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
                    // Type selector
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.divider, width: 1.5),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: _postTypes.map((entry) {
                          final isActive =
                              _selectedType == entry.$1;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedType = entry.$1);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 9),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.textPrimary
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  entry.$2,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption
                                      .copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Anonymous toggle
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Post anonymously',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(
                                      fontWeight: FontWeight.w600),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isAnonymous = !_isAnonymous);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                width: 51,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: _isAnonymous
                                      ? AppColors.sageGreen
                                      : AppColors.divider,
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  alignment: _isAnonymous
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 25,
                                    height: 25,
                                    margin: const EdgeInsets
                                        .symmetric(horizontal: 3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Text area
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 240),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(14),
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
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        maxLength: 1000,
                        autofocus: false,
                        style: AppTextStyles.bodyMedium
                            .copyWith(height: 1.7),
                        decoration: InputDecoration(
                          hintText:
                              'Share what\'s on your mind…',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(
                                  color: AppColors.textTertiary),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 4, bottom: 14),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$wordCount words',
                              style: AppTextStyles.caption),
                          Text('${text.length} / 1000',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    // Context note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 2),
                      ),
                      child: Text(
                        'This will be shown to community members with similar losses.',
                        style: AppTextStyles.caption
                            .copyWith(height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Post button
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgGray,
                border: Border(
                    top: BorderSide(
                        color: AppColors.divider, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: LuminaryButton(
                label: 'Share with community',
                onTap: canPost ? _post : null,
                isLoading: _isPosting,
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

// ── Post Success View (S-74) ──────────────────────────────────────────────────

class _PostSuccessView extends StatelessWidget {
  final String context;
  const _PostSuccessView({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CandleIcon(size: 56, flameColor: AppColors.warmAmber),
              const SizedBox(height: 20),
              Text(
                'Your words are out there.',
                style: AppTextStyles.displayH1.copyWith(
                  fontSize: 26,
                  letterSpacing: -0.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Posted $context.',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary, height: 1.65),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.amberTint,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  border: Border(left: BorderSide(color: AppColors.warmAmber, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Luminary',
                        style: AppTextStyles.sectionLabel.copyWith(
                            color: AppColors.amberDark, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text(
                      'Sharing something so personal takes real courage. Whatever comes back from the community — you\'ve already done the brave part.',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w300, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LuminaryButton(
                label: 'Return to community',
                onTap: () => ctx.go('/home/community'),
              ),
              const SizedBox(height: 10),
              LuminaryButton(
                label: 'Go home',
                onTap: () => ctx.go('/home/dashboard'),
                style: LuminaryButtonStyle.ghost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
