import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/checkin_entry.dart';
import '../models/community_post.dart';
import '../models/journal_entry.dart';
import '../models/loss_profile.dart';
import '../models/memory_entry.dart';
import '../models/user_profile.dart';
import '../providers/checkin_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/loss_profile_provider.dart';
import '../providers/memory_provider.dart';
import '../providers/user_profile_provider.dart';

const _uuid = Uuid();

// ── User Profiles ─────────────────────────────────────────────────────────────

final mockUsers = [
  // User 0 — Sarah Mitchell (parent, 6 months, active)
  UserProfile(
    id: 'mock-sarah-001',
    email: 'sarah@mock.dev',
    displayName: 'Sarah Mitchell',
    subscriptionStatus: SubscriptionStatus.active,
  ),
  // User 1 — James Park (spouse, 45 days, trial)
  UserProfile(
    id: 'mock-james-001',
    email: 'james@example.com',
    displayName: 'James Park',
    subscriptionStatus: SubscriptionStatus.trial,
    trialEndDate: DateTime.now().add(const Duration(days: 7)),
  ),
  // User 2 — Priya Sharma (pet, 14 days, expired)
  UserProfile(
    id: 'mock-priya-001',
    email: 'priya@example.com',
    displayName: 'Priya Sharma',
    subscriptionStatus: SubscriptionStatus.expired,
    trialEndDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// ── Loss Profiles ─────────────────────────────────────────────────────────────

final mockLossProfiles = [
  // Sarah — Eleanor (parent)
  LossProfile(
    id: 'loss-sarah-001',
    deceasedName: 'Eleanor',
    relationship: RelationshipType.parent,
    personalDescription: 'My mum. She loved gardening and always called on Mondays.',
    dateOfDeath: DateTime.now().subtract(const Duration(days: 180)),
    dateOfBirth: DateTime(1945, 3, 12),
    lossType: LossType.expected,
    trackedHolidays: [HolidayType.christmas, HolidayType.mothersDay, HolidayType.newYear],
  ),
  // James — Marcus (spouse)
  LossProfile(
    id: 'loss-james-001',
    deceasedName: 'Marcus',
    relationship: RelationshipType.spouse,
    dateOfDeath: DateTime.now().subtract(const Duration(days: 45)),
    lossType: LossType.sudden,
    trackedHolidays: [HolidayType.christmas, HolidayType.thanksgiving],
  ),
  // Priya — Buddy (pet)
  LossProfile(
    id: 'loss-priya-001',
    deceasedName: 'Buddy',
    relationship: RelationshipType.pet,
    isPet: true,
    dateOfDeath: DateTime.now().subtract(const Duration(days: 14)),
    lossType: LossType.expected,
    trackedHolidays: [],
  ),
];

// ── Check-In Data ─────────────────────────────────────────────────────────────

List<CheckinEntry> mockCheckins(int userIndex) {
  if (userIndex != 0) return [];
  final now = DateTime.now();
  final intensities = [7, 8, 6, 9, 7, 5, 8, 6, 7, 5, 8, 6, 4, 7, 5, 6, 4, 7, 5, 3, 6, 4, 5, 3, 6, 4, 8, 5, 4, 3];
  final skipDays = {3, 11, 19}; // skip 3 random days for realism
  final entries = <CheckinEntry>[];
  for (var i = 0; i < 30; i++) {
    if (skipDays.contains(i)) continue;
    final intensity = intensities[i];
    entries.add(CheckinEntry(
      id: _uuid.v4(),
      date: DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i)),
      waveIntensity: intensity,
      emotions: _emotionsForIntensity(intensity),
      isHardDate: i == 26, // day 27 spike
    ));
  }
  return entries;
}

List<EmotionType> _emotionsForIntensity(int intensity) {
  if (intensity >= 8) return [EmotionType.heavy, EmotionType.missing, EmotionType.exhausted];
  if (intensity >= 6) return [EmotionType.sad, EmotionType.lonely];
  if (intensity >= 4) return [EmotionType.numb, EmotionType.disconnected];
  return [EmotionType.peaceful, EmotionType.grateful];
}

// ── Journal Entries ───────────────────────────────────────────────────────────

List<JournalEntry> mockJournal(int userIndex) {
  final now = DateTime.now();
  if (userIndex == 1) {
    return [
      JournalEntry(
        id: _uuid.v4(), date: now.subtract(const Duration(days: 3)),
        title: 'Everything changed', content: 'I keep expecting Marcus to walk through the door. The silence is deafening.',
        waveIntensityAtTime: 9, intensityLevel: JournalIntensityLevel.high, isHardDate: false,
      ),
    ];
  }
  if (userIndex == 2) {
    return [
      JournalEntry(
        id: _uuid.v4(), date: now.subtract(const Duration(days: 2)),
        title: 'Missing Buddy', content: 'The house is so quiet without him. His bed is still in the corner.',
        waveIntensityAtTime: 7, intensityLevel: JournalIntensityLevel.moderate,
      ),
    ];
  }
  // Sarah — 8 entries
  return [
    JournalEntry(
      id: _uuid.v4(), date: now,
      title: 'Today', content: 'I woke up and for a moment forgot she was gone. Then it came back.',
      waveIntensityAtTime: 5, intensityLevel: JournalIntensityLevel.gentle,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 2)),
      title: 'Six months', content: 'Half a year. I never thought I could carry this and I am.',
      waveIntensityAtTime: 7, intensityLevel: JournalIntensityLevel.moderate, isHardDate: true, isFavourite: true,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 7)),
      title: 'Something she would have loved', content: 'The garden is blooming exactly the way she used to describe.',
      waveIntensityAtTime: 3, intensityLevel: JournalIntensityLevel.gentle, isFavourite: true,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 10)),
      title: 'I got angry today', content: "I don't know who I was angry at. Her for leaving. Myself for not saying more.",
      waveIntensityAtTime: 8, intensityLevel: JournalIntensityLevel.high,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 14)),
      title: 'Her birthday is coming', content: 'March 12th is three weeks away. I have no idea what to do with that day.',
      waveIntensityAtTime: 6, intensityLevel: JournalIntensityLevel.moderate,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 18)),
      title: 'A small moment of peace', content: "I made her recipe for the first time. It tasted right. I didn't cry.",
      waveIntensityAtTime: 4, intensityLevel: JournalIntensityLevel.gentle,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 22)),
      title: 'Going through her things', content: "I opened her wardrobe today. Everything still smells like her.",
      waveIntensityAtTime: 8, intensityLevel: JournalIntensityLevel.high,
    ),
    JournalEntry(
      id: _uuid.v4(), date: now.subtract(const Duration(days: 25)),
      title: 'The first Monday', content: 'Eleanor always called on Mondays at half past ten. The phone was quiet.',
      waveIntensityAtTime: 7, intensityLevel: JournalIntensityLevel.moderate,
    ),
  ];
}

// ── Memory Entries ────────────────────────────────────────────────────────────

List<MemoryEntry> mockMemories(int userIndex) {
  final now = DateTime.now();
  final profileId = mockLossProfiles[userIndex].id;
  if (userIndex == 1) {
    return [
      MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: "His laugh", textContent: "Marcus had a laugh that filled any room. I heard it in a dream last night.", addedAt: now.subtract(const Duration(days: 5)), isSharedWithAI: true),
    ];
  }
  if (userIndex == 2) {
    return [
      MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: "Morning walks", textContent: "Buddy used to drag me outside every morning at 7am, no matter the weather.", addedAt: now.subtract(const Duration(days: 3)), isSharedWithAI: true),
    ];
  }
  return [
    MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: 'Her laugh', textContent: 'Eleanor had this specific laugh when something caught her off guard. A real laugh, not polite.', addedAt: now.subtract(const Duration(days: 2)), isSharedWithAI: true),
    MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: 'The garden', textContent: 'Every Sunday morning she would be in the garden by 7am. Tulips first, then roses.', addedAt: now.subtract(const Duration(days: 5)), isSharedWithAI: true),
    MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: 'Her recipe', textContent: 'Three cups of flour, two eggs — she never wrote it down. I had to rebuild it from memory.', addedAt: now.subtract(const Duration(days: 8)), isSharedWithAI: false),
    MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: 'Last Christmas', textContent: "We didn't know it would be the last one. She wore the red jumper I gave her.", addedAt: now.subtract(const Duration(days: 12)), isSharedWithAI: false),
    MemoryEntry(id: _uuid.v4(), lossProfileId: profileId, title: 'What she always said', textContent: "Whenever I was worried she would say 'You've faced harder things than this, love.'", addedAt: now.subtract(const Duration(days: 20)), isSharedWithAI: true),
  ];
}

// ── Community Posts ───────────────────────────────────────────────────────────

List<CommunityPost> mockCommunityPosts() {
  final now = DateTime.now();
  return [
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "Lost my mum 5 months ago. The silence in the house is the hardest part. I keep turning to tell her things.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 20, resonanceCount: 14, replyCount: 4, createdAt: now.subtract(const Duration(hours: 1))),
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "Does anyone else find themselves picking up the phone to call them? I did it again this morning.", postType: PostType.question, lossType: RelationshipType.parent, weeksOutFromLoss: 12, resonanceCount: 23, replyCount: 9, createdAt: now.subtract(const Duration(hours: 3))),
    CommunityPost(id: _uuid.v4(), isAnonymous: false, authorDisplayName: 'Margaret C.', content: "Her birthday is next week. I have no idea how to get through it. Any advice welcome.", postType: PostType.seekingSupport, lossType: RelationshipType.parent, weeksOutFromLoss: 8, resonanceCount: 31, replyCount: 14, createdAt: now.subtract(const Duration(hours: 6)), isHardDateBadge: true),
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "I made her favourite dish today. Cried the whole time. Also felt strangely close to her.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 16, resonanceCount: 18, replyCount: 7, createdAt: now.subtract(const Duration(days: 1))),
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "Six months feels both like yesterday and forever ago. Is that normal?", postType: PostType.question, lossType: RelationshipType.parent, weeksOutFromLoss: 26, resonanceCount: 27, replyCount: 11, createdAt: now.subtract(const Duration(days: 1))),
    CommunityPost(id: _uuid.v4(), isAnonymous: false, authorDisplayName: 'David T.', content: "Seeking support — how do you handle going back to work? I can't concentrate on anything.", postType: PostType.seekingSupport, lossType: RelationshipType.parent, weeksOutFromLoss: 6, resonanceCount: 9, replyCount: 5, createdAt: now.subtract(const Duration(days: 2))),
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "Memory share — she used to leave notes in my lunch until I was 30. Found a box of them last week.", postType: PostType.memoryShare, lossType: RelationshipType.parent, weeksOutFromLoss: 40, resonanceCount: 44, replyCount: 21, createdAt: now.subtract(const Duration(days: 2))),
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "The grief wave feature showed me I've been improving even when it didn't feel like it. Grateful for this app.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 30, resonanceCount: 12, replyCount: 3, createdAt: now.subtract(const Duration(days: 3))),
    CommunityPost(id: _uuid.v4(), isAnonymous: false, authorDisplayName: 'Priya S.', content: "Has anyone tried grief counselling alongside this app? Looking for people's experiences.", postType: PostType.question, lossType: RelationshipType.parent, weeksOutFromLoss: 14, resonanceCount: 8, replyCount: 6, createdAt: now.subtract(const Duration(days: 3))),
    CommunityPost(id: _uuid.v4(), isAnonymous: true, content: "One year tomorrow. I made it. I didn't think I would but I did.", postType: PostType.sharing, lossType: RelationshipType.parent, weeksOutFromLoss: 52, resonanceCount: 67, replyCount: 34, createdAt: now.subtract(const Duration(days: 4)), isHardDateBadge: true),
  ];
}

// ── MockDataService ───────────────────────────────────────────────────────────

class MockDataService {
  static const _kMockUserIndex = 'mock_user_index';

  static Future<int> getCurrentUserIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kMockUserIndex) ?? 0;
  }

  static Future<void> loadUser(int userIndex, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMockUserIndex, userIndex);

    // Update user profile
    ref.read(userProfileProvider.notifier).updateProfile(mockUsers[userIndex]);

    // Update loss profile
    await ref.read(lossProfileProvider.notifier).saveLossProfile(mockLossProfiles[userIndex]);

    // Update checkins
    ref.read(checkinProvider.notifier).loadMockData(mockCheckins(userIndex));

    // Update journal
    ref.read(journalProvider.notifier).loadMockData(mockJournal(userIndex));

    // Update memories
    ref.read(memoryProvider.notifier).loadMockData(mockMemories(userIndex));

    // Community posts stay shared across users
  }
}
