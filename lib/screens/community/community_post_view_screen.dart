import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

class CommunityPostViewScreen extends ConsumerStatefulWidget {
  final CommunityPost post;
  const CommunityPostViewScreen({super.key, required this.post});

  @override
  ConsumerState<CommunityPostViewScreen> createState() =>
      _CommunityPostViewScreenState();
}

class _CommunityPostViewScreenState
    extends ConsumerState<CommunityPostViewScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Mock replies for display
  static final _mockReplies = [
    (
      'Anonymous · 3 months out',
      'Yes. Completely. The second month the world moves on and you realise the loss is permanent in a way the first month doesn\'t let you see.',
    ),
    (
      'James T. · 8 months out',
      'It does get lighter — not easier, but lighter. You carry the same weight but you get stronger. You\'re not alone in this.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentPost = ref
        .watch(communityProvider)
        .firstWhere((p) => p.id == post.id, orElse: () => post);
    final resonatedIds = ref.read(communityProvider.notifier).resonatedPostIds;

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
                    onTap: () => context.pop(),
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text('Community Post',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: _mockReplies.length + 3,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AuthorCard(
                        post: post,
                        timeAgo: _timeAgo(post.createdAt));
                  }
                  if (index == 1) {
                    return _PostBody(
                        post: currentPost,
                        isResonated: resonatedIds.contains(post.id),
                        onResonate: () => ref
                            .read(communityProvider.notifier)
                            .resonatePost(post.id));
                  }
                  if (index == 2) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'REPLIES (${currentPost.replyCount})',
                        style: AppTextStyles.sectionLabel,
                      ),
                    );
                  }
                  final reply = _mockReplies[index - 3];
                  return _ReplyCard(
                      author: reply.$1, content: reply.$2);
                },
              ),
            ),
            // Reply input
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgGray,
                border: Border(
                    top: BorderSide(
                        color: AppColors.divider, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
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
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'Write a reply…',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(
                                  color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                        ),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  final CommunityPost post;
  final String timeAgo;
  const _AuthorCard({required this.post, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.bgGray,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person_outline,
                  size: 20, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.isAnonymous
                      ? 'Anonymous'
                      : post.authorDisplayName ?? '',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${post.weeksOutFromLoss} weeks out — ${post.lossType.name} loss',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(timeAgo, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  final CommunityPost post;
  final bool isResonated;
  final VoidCallback onResonate;
  const _PostBody({required this.post, required this.isResonated, required this.onResonate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.content.length > 40
              ? post.content.substring(0, 40)
              : post.content,
          style: AppTextStyles.screenTitle,
        ),
        const SizedBox(height: 14),
        Text(post.content,
            style: AppTextStyles.bodyLarge
                .copyWith(height: 1.75)),
        const SizedBox(height: 20),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onResonate();
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isResonated ? AppColors.warmAmber : AppColors.cardBorder, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.warmAmber,
                      offset: AppDimensions.neoShadowOffset,
                      blurRadius: AppDimensions.neoShadowBlur,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CandleIcon(size: 16, flameColor: isResonated ? AppColors.warmAmber : AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      isResonated ? 'Resonated · ${post.resonanceCount}' : 'Resonate · ${post.resonanceCount}',
                      style: AppTextStyles.buttonLabel.copyWith(
                        fontSize: 14,
                        color: isResonated ? AppColors.warmAmber : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final String author;
  final String content;
  const _ReplyCard(
      {required this.author, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(author,
              style: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(content,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontSize: 14, height: 1.6)),
        ],
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
