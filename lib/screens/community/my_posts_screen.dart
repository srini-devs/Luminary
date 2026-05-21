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
import '../../widgets/luminary_button.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(communityProvider);
    final myPosts = ref.read(communityProvider.notifier).myPosts;
    final anonCount = myPosts.where((p) => p.isAnonymous).length;

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
                    child: Text('My posts',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: myPosts.isEmpty
                  ? _EmptyMyPosts(onWrite: () => context.push('/home/community/create'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      children: [
                        // Summary card
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.cardRadius),
                            border: Border.all(
                                color: AppColors.cardBorder, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${myPosts.length} post${myPosts.length == 1 ? '' : 's'} · $anonCount anonymous',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/home/community/create');
                                },
                                child: Text(
                                  'Write a post ›',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warmAmber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Post cards
                        ...myPosts.map((post) => _MyPostCard(
                              post: post,
                              onTap: () => context.push(
                                '/home/community/post/${post.id}',
                                extra: post,
                              ),
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  const _MyPostCard({required this.post, required this.onTap});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final weeks = diff.inDays ~/ 7;
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.cardBorder, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  post.isAnonymous ? 'You · Anonymous' : 'You · Named',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(_timeAgo(post.createdAt),
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              post.content.length > 100
                  ? '${post.content.substring(0, 100)}…'
                  : post.content,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13, height: 1.55),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CandleIcon(size: 14, flameColor: AppColors.warmAmber),
                const SizedBox(width: 5),
                Text('${post.resonanceCount}',
                    style: AppTextStyles.caption),
                const SizedBox(width: 14),
                const Text('💬', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text('${post.replyCount}',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMyPosts extends StatelessWidget {
  final VoidCallback onWrite;
  const _EmptyMyPosts({required this.onWrite});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CandleIcon(size: 48, flameColor: AppColors.warmAmber),
          const SizedBox(height: 20),
          Text(
            'You haven\'t posted yet.',
            style: AppTextStyles.displayH1.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When you share with the community, your posts will appear here.',
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary, height: 1.65),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          LuminaryButton(label: 'Write a post', onTap: onWrite),
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
