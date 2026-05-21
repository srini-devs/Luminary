import 'loss_profile.dart';

enum PostType { sharing, seekingSupport, memoryShare, question }

class CommunityPost {
  final String id;
  final String? authorDisplayName;
  final bool isAnonymous;
  final String content;
  final PostType postType;
  final RelationshipType lossType;
  final int weeksOutFromLoss;
  final int resonanceCount;
  final int replyCount;
  final DateTime createdAt;
  final bool isHardDateBadge;
  final bool isOwnPost;

  const CommunityPost({
    required this.id,
    this.authorDisplayName,
    required this.isAnonymous,
    required this.content,
    required this.postType,
    required this.lossType,
    required this.weeksOutFromLoss,
    this.resonanceCount = 0,
    this.replyCount = 0,
    required this.createdAt,
    this.isHardDateBadge = false,
    this.isOwnPost = false,
  });

  CommunityPost copyWith({
    String? id,
    String? authorDisplayName,
    bool? isAnonymous,
    String? content,
    PostType? postType,
    RelationshipType? lossType,
    int? weeksOutFromLoss,
    int? resonanceCount,
    int? replyCount,
    DateTime? createdAt,
    bool? isHardDateBadge,
    bool? isOwnPost,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      lossType: lossType ?? this.lossType,
      weeksOutFromLoss: weeksOutFromLoss ?? this.weeksOutFromLoss,
      resonanceCount: resonanceCount ?? this.resonanceCount,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      isHardDateBadge: isHardDateBadge ?? this.isHardDateBadge,
      isOwnPost: isOwnPost ?? this.isOwnPost,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorDisplayName': authorDisplayName,
        'isAnonymous': isAnonymous,
        'content': content,
        'postType': postType.index,
        'lossType': lossType.index,
        'weeksOutFromLoss': weeksOutFromLoss,
        'resonanceCount': resonanceCount,
        'replyCount': replyCount,
        'createdAt': createdAt.toIso8601String(),
        'isHardDateBadge': isHardDateBadge,
        'isOwnPost': isOwnPost,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id: j['id'] as String,
        authorDisplayName: j['authorDisplayName'] as String?,
        isAnonymous: j['isAnonymous'] as bool,
        content: j['content'] as String,
        postType: PostType.values[j['postType'] as int],
        lossType: RelationshipType.values[j['lossType'] as int],
        weeksOutFromLoss: j['weeksOutFromLoss'] as int,
        resonanceCount: (j['resonanceCount'] as int?) ?? 0,
        replyCount: (j['replyCount'] as int?) ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isHardDateBadge: (j['isHardDateBadge'] as bool?) ?? false,
        isOwnPost: (j['isOwnPost'] as bool?) ?? false,
      );
}
