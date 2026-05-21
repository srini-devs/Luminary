import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/community_post.dart';
import '../../models/loss_profile.dart';
import '../../providers/community_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/section_header.dart';

const _relLabels = ['Parent', 'Spouse', 'Child', 'Sibling', 'Friend', 'Pet', 'Any'];
const _timeLabels = ['0–3 months', '3–6 months', '6–12 months', '1–2 years', '2+ years', 'Any'];
const _typeLabels = ['All posts', 'Hard date', 'Seeking support', 'Sharing', 'Milestones'];
final _relTypes = [
  RelationshipType.parent,
  RelationshipType.spouse,
  RelationshipType.child,
  RelationshipType.sibling,
  RelationshipType.friend,
  RelationshipType.pet,
  null,
];
final _timeRanges = [(0, 13), (13, 26), (26, 52), (52, 104), (104, 99999)];

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
  int _relIdx = 0;
  int _timeIdx = 0;
  int _typeIdx = 0;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(lossProfileProvider);
    _relIdx = _relIdxFromRelType(profile?.relationship);
    _timeIdx = _timeIdxFromProfile(profile);
  }

  int _relIdxFromRelType(RelationshipType? rel) {
    if (rel == null) return 6;
    return switch (rel) {
      RelationshipType.parent => 0,
      RelationshipType.spouse => 1,
      RelationshipType.child => 2,
      RelationshipType.sibling => 3,
      RelationshipType.friend => 4,
      RelationshipType.pet => 5,
      RelationshipType.other => 6,
    };
  }

  int _timeIdxFromProfile(LossProfile? profile) {
    if (profile == null) return 5;
    final weeks = DateTime.now().difference(profile.dateOfDeath).inDays ~/ 7;
    if (weeks < 13) return 0;
    if (weeks < 26) return 1;
    if (weeks < 52) return 2;
    if (weeks < 104) return 3;
    return 4;
  }

  List<CommunityPost> _filtered(List<CommunityPost> posts) {
    var result = posts;
    if (_relIdx < 6) {
      final type = _relTypes[_relIdx];
      result = result.where((p) => p.lossType == type).toList();
    }
    if (_timeIdx < 5) {
      final range = _timeRanges[_timeIdx];
      result = result.where((p) => p.weeksOutFromLoss >= range.$1 && p.weeksOutFromLoss < range.$2).toList();
    }
    if (_typeIdx > 0) {
      result = switch (_typeIdx) {
        1 => result.where((p) => p.isHardDateBadge).toList(),
        2 => result.where((p) => p.postType == PostType.seekingSupport).toList(),
        3 => result.where((p) => p.postType == PostType.sharing).toList(),
        4 => result.where((p) => p.postType == PostType.memoryShare).toList(),
        _ => result,
      };
    }
    return result;
  }

  String get _stripLabel {
    final rel = _relLabels[_relIdx].toLowerCase();
    final time = _timeLabels[_timeIdx];
    return 'Showing: $rel loss · $time';
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        relIdx: _relIdx,
        timeIdx: _timeIdx,
        typeIdx: _typeIdx,
        onApply: (r, t, p) {
          HapticFeedback.mediumImpact();
          setState(() {
            _relIdx = r;
            _timeIdx = t;
            _typeIdx = p;
          });
          Navigator.of(context).pop();
        },
        onReset: () {
          HapticFeedback.selectionClick();
          setState(() {
            final profile = ref.read(lossProfileProvider);
            _relIdx = _relIdxFromRelType(profile?.relationship);
            _timeIdx = _timeIdxFromProfile(profile);
            _typeIdx = 0;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(communityProvider);
    final resonatedIds = ref.read(communityProvider.notifier).resonatedPostIds;
    final myCount = ref.read(communityProvider.notifier).myPosts.length;
    final filtered = _filtered(posts);

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _CircleBtn(
                        onTap: () => context.go('/home/dashboard'),
                        child: const Text('‹',
                            style: TextStyle(
                                fontSize: 22,
                                color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: Text('Community',
                            style: AppTextStyles.screenTitle,
                            textAlign: TextAlign.center),
                      ),
                      _CircleBtn(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _openFilterSheet();
                        },
                        child: const Icon(
                            Icons.filter_list_outlined,
                            size: 18,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(onWrite: () => context.push('/home/community/create'), onReset: _openFilterSheet)
                      : RefreshIndicator(
                          color: AppColors.warmAmber,
                          onRefresh: () async =>
                              Future.delayed(const Duration(milliseconds: 500)),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: filtered.length + 3,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _FilterStrip(
                                  label: _stripLabel,
                                  onChangeTap: () {
                                    HapticFeedback.selectionClick();
                                    _openFilterSheet();
                                  },
                                );
                              }
                              if (index == 1) {
                                return _MyPostsRow(
                                  count: myCount,
                                  onTap: () => context.push('/home/community/my-posts'),
                                );
                              }
                              if (index == 2) {
                                return const SectionHeader('RECENT POSTS');
                              }
                              final post = filtered[index - 3];
                              return _PostCard(
                                post: post,
                                isResonated: resonatedIds.contains(post.id),
                                onTap: () => context.push(
                                  '/home/community/post/${post.id}',
                                  extra: post,
                                ),
                                onResonate: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(communityProvider.notifier).resonatePost(post.id);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 90,
              right: 24,
              child: GestureDetector(
                onTap: () => context.push('/home/community/create'),
                child: Container(
                  width: AppDimensions.fabSize,
                  height: AppDimensions.fabSize,
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.amberDark, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.amberDark,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State (S-38) ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onWrite;
  final VoidCallback onReset;
  const _EmptyState({required this.onWrite, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CandleIcon(size: 32, flameColor: AppColors.warmAmber.withAlpha(200)),
              const SizedBox(width: 16),
              CandleIcon(size: 40, flameColor: AppColors.warmAmber),
              const SizedBox(width: 16),
              CandleIcon(size: 32, flameColor: AppColors.warmAmber.withAlpha(200)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.cardBorder, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'No posts yet from people at your stage.',
                  style: AppTextStyles.displayH1.copyWith(
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You could be the first to share. Your words might be exactly what someone else needs to hear today.',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary, height: 1.65),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LuminaryButton(label: 'Write a post', onTap: onWrite),
          const SizedBox(height: 10),
          LuminaryButton(
            label: 'Explore wider community',
            onTap: onReset,
            style: LuminaryButtonStyle.ghost,
          ),
        ],
      ),
    );
  }
}

// ── Filter Strip ──────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  final String label;
  final VoidCallback onChangeTap;
  const _FilterStrip({required this.label, required this.onChangeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: onChangeTap,
            child: Text(
              'Change ›',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warmAmber,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Posts Row ──────────────────────────────────────────────────────────────

class _MyPostsRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _MyPostsRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.cardBorder, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My posts ($count)',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'View ›',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warmAmber,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Sheet (S-55) ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final int relIdx, timeIdx, typeIdx;
  final void Function(int, int, int) onApply;
  final VoidCallback onReset;
  const _FilterSheet({
    required this.relIdx,
    required this.timeIdx,
    required this.typeIdx,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _r, _t, _p;

  @override
  void initState() {
    super.initState();
    _r = widget.relIdx;
    _t = widget.timeIdx;
    _p = widget.typeIdx;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 80),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    'Filter community',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader('WHO YOU LOST'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_relLabels.length, (i) => _FilterChip(
                label: _relLabels[i],
                selected: _r == i,
                onTap: () { HapticFeedback.selectionClick(); setState(() => _r = i); },
              )),
            ),
            const SizedBox(height: 16),
            const SectionHeader('TIME SINCE LOSS'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_timeLabels.length, (i) => _FilterChip(
                label: _timeLabels[i],
                selected: _t == i,
                onTap: () { HapticFeedback.selectionClick(); setState(() => _t = i); },
              )),
            ),
            const SizedBox(height: 16),
            const SectionHeader('POST TYPE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_typeLabels.length, (i) => _FilterChip(
                label: _typeLabels[i],
                selected: _p == i,
                onTap: () { HapticFeedback.selectionClick(); setState(() => _p = i); },
              )),
            ),
            const SizedBox(height: 24),
            LuminaryButton(
              label: 'Apply filters',
              onTap: () => widget.onApply(_r, _t, _p),
            ),
            const SizedBox(height: 10),
            LuminaryButton(
              label: 'Reset all',
              onTap: widget.onReset,
              style: LuminaryButtonStyle.ghost,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.softPurple : AppColors.divider,
            width: selected ? 2.5 : 2,
          ),
          boxShadow: selected
              ? [const BoxShadow(
                  color: AppColors.softPurple,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                )]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isResonated;
  final VoidCallback onTap;
  final VoidCallback onResonate;
  const _PostCard({
    required this.post,
    required this.isResonated,
    required this.onTap,
    required this.onResonate,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _postTypeLabel(PostType type) {
    return switch (type) {
      PostType.sharing => 'Sharing',
      PostType.seekingSupport => 'Seeking support',
      PostType.memoryShare => 'Memory',
      PostType.question => 'Question',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isHardDate = post.isHardDateBadge;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isHardDate ? AppColors.softPurple : AppColors.cardBorder,
            width: 2,
          ),
          boxShadow: isHardDate
              ? const [
                  BoxShadow(
                    color: AppColors.softPurple,
                    offset: AppDimensions.neoShadowOffset,
                    blurRadius: AppDimensions.neoShadowBlur,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isHardDate) ...[
                        const CandleIcon(size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'HARD DATE',
                          style: AppTextStyles.aiAccent.copyWith(
                            color: AppColors.softPurple,
                            fontSize: 11,
                          ),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.bgGray,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _postTypeLabel(post.postType),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(_timeAgo(post.createdAt), style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.isAnonymous
                    ? 'Anonymous · ${post.weeksOutFromLoss} weeks out'
                    : '${post.authorDisplayName} · ${post.weeksOutFromLoss} weeks out',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                post.content.length > 160
                    ? '${post.content.substring(0, 160)}…'
                    : post.content,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: onResonate,
                    child: Row(
                      children: [
                        CandleIcon(
                          size: 14,
                          flameColor: isResonated
                              ? AppColors.warmAmber
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.resonanceCount}',
                          style: AppTextStyles.caption.copyWith(
                            color: isResonated ? AppColors.warmAmber : null,
                            fontWeight: isResonated ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('💬', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text('${post.replyCount}', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
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
