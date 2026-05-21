import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/community_post.dart';
import '../models/loss_profile.dart';

const _cuuid = Uuid();
const _kPostsKey = 'community_posts_cache';
const _kResonatedKey = 'community_resonated_ids';

List<CommunityPost> _defaultPosts() {
  final now = DateTime.now();
  return [
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "Lost my mum 5 months ago. The silence in the house is the hardest part.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 20, resonanceCount: 14, replyCount: 4, createdAt: now.subtract(const Duration(hours: 1))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "Does anyone else find themselves picking up the phone to call them?", postType: PostType.question, lossType: RelationshipType.parent, weeksOutFromLoss: 12, resonanceCount: 23, replyCount: 9, createdAt: now.subtract(const Duration(hours: 3))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: false, authorDisplayName: 'Margaret C.', content: "Her birthday is next week. I have no idea how to get through it.", postType: PostType.seekingSupport, lossType: RelationshipType.parent, weeksOutFromLoss: 8, resonanceCount: 31, replyCount: 14, createdAt: now.subtract(const Duration(hours: 6)), isHardDateBadge: true),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "I made her favourite dish today. Cried the whole time. Also felt strangely close to her.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 16, resonanceCount: 18, replyCount: 7, createdAt: now.subtract(const Duration(days: 1))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "Six months feels both like yesterday and forever ago.", postType: PostType.question, lossType: RelationshipType.parent, weeksOutFromLoss: 26, resonanceCount: 27, replyCount: 11, createdAt: now.subtract(const Duration(days: 1))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: false, authorDisplayName: 'David T.', content: "Seeking support — how do you handle going back to work?", postType: PostType.seekingSupport, lossType: RelationshipType.parent, weeksOutFromLoss: 6, resonanceCount: 9, replyCount: 5, createdAt: now.subtract(const Duration(days: 2))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "She used to leave notes in my lunch until I was 30. Found a box of them last week.", postType: PostType.memoryShare, lossType: RelationshipType.parent, weeksOutFromLoss: 40, resonanceCount: 44, replyCount: 21, createdAt: now.subtract(const Duration(days: 2))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "The grief wave feature showed me I've been improving even when it didn't feel like it.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 30, resonanceCount: 12, replyCount: 3, createdAt: now.subtract(const Duration(days: 3))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: false, authorDisplayName: 'Priya S.', content: "Has anyone tried grief counselling alongside this app?", postType: PostType.question, lossType: RelationshipType.parent, weeksOutFromLoss: 14, resonanceCount: 8, replyCount: 6, createdAt: now.subtract(const Duration(days: 3))),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "One year tomorrow. I made it. I didn't think I would but I did.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 52, resonanceCount: 67, replyCount: 34, createdAt: now.subtract(const Duration(days: 4)), isHardDateBadge: true),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "Her birthday is in 3 days and I don't know what to do. I keep thinking about calling her — I forget she's gone.", postType: PostType.seekingSupport, lossType: RelationshipType.parent, weeksOutFromLoss: 26, resonanceCount: 47, replyCount: 18, createdAt: now.subtract(const Duration(days: 2)), isOwnPost: true),
    CommunityPost(id: _cuuid.v4(), isAnonymous: false, authorDisplayName: 'Sarah M.', content: "I laughed today — the first time in weeks. Something silly. And then I waited to feel guilty. I didn't.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 26, resonanceCount: 93, replyCount: 34, createdAt: now.subtract(const Duration(days: 7)), isOwnPost: true),
    CommunityPost(id: _cuuid.v4(), isAnonymous: true, content: "I baked her lemon cake for her birthday. Ate one slice. Left the rest on the neighbour's step — she would have approved.", postType: PostType.memoryShare, lossType: RelationshipType.parent, weeksOutFromLoss: 24, resonanceCount: 187, replyCount: 67, createdAt: now.subtract(const Duration(days: 14)), isOwnPost: true),
  ];
}

class CommunityNotifier extends StateNotifier<List<CommunityPost>> {
  CommunityNotifier() : super([]) {
    _loadFromPrefs();
  }

  final Set<String> _resonatedIds = {};
  Set<String> get resonatedPostIds => Set.unmodifiable(_resonatedIds);
  List<CommunityPost> get myPosts => state.where((p) => p.isOwnPost).toList();

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPostsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        state = list.map((j) => CommunityPost.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {
        state = _defaultPosts();
      }
    } else {
      state = _defaultPosts();
    }
    final resonated = prefs.getStringList(_kResonatedKey) ?? [];
    _resonatedIds.addAll(resonated);
    _persistPosts();
  }

  Future<void> _persistPosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPostsKey, jsonEncode(state.map((p) => p.toJson()).toList()));
  }

  Future<void> _persistResonated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kResonatedKey, _resonatedIds.toList());
  }

  // TODO(backend): Fetch community posts from Supabase with pagination
  void addPost(CommunityPost post) {
    state = [post.copyWith(isOwnPost: true), ...state];
    _persistPosts();
  }

  // TODO(backend): Delete post from Supabase
  void removePost(String id) {
    state = state.where((p) => p.id != id).toList();
    _persistPosts();
  }

  // TODO(backend): Update resonance count in Supabase
  void resonatePost(String id) {
    final alreadyResonated = _resonatedIds.contains(id);
    if (alreadyResonated) {
      _resonatedIds.remove(id);
      state = state.map((p) {
        if (p.id != id) return p;
        return p.copyWith(resonanceCount: (p.resonanceCount - 1).clamp(0, 999999));
      }).toList();
    } else {
      _resonatedIds.add(id);
      state = state.map((p) {
        if (p.id != id) return p;
        return p.copyWith(resonanceCount: p.resonanceCount + 1);
      }).toList();
    }
    _persistPosts();
    _persistResonated();
  }

  void loadMockData(List<CommunityPost> posts) {
    state = posts;
    _persistPosts();
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, List<CommunityPost>>((ref) => CommunityNotifier());
