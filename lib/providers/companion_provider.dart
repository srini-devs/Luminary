import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_message.dart';
import '../models/loss_profile.dart';
import 'checkin_provider.dart';
import 'grief_calendar_provider.dart';
import 'loss_profile_provider.dart';
import 'memory_provider.dart';

const _uuid = Uuid();
const _kSessionSummaryKey = 'companion_last_summary';

class CompanionNotifier extends StateNotifier<List<AiMessage>> {
  final Ref _ref;
  CompanionNotifier(this._ref) : super([]);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  bool _highIntensityPending = false;
  bool get highIntensityPending => _highIntensityPending;
  void setHighIntensityPending(bool value) => _highIntensityPending = value;

  // ── Context assembly ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> buildContext() async {
    final profile = _ref.read(lossProfileProvider);
    final notifier = _ref.read(checkinProvider.notifier);
    final todaysEntry = notifier.todaysEntry;
    final last3Scores = notifier.last3Scores;
    final last3Emotions = notifier.last3Emotions;
    final memories = _ref.read(memoryProvider);
    final sharedMemories = memories.where((m) => m.isSharedWithAI).toList();
    final nextHardDate = _ref.read(nextUpcomingHardDateProvider);
    final todaysHardDate = _ref.read(todaysHardDateProvider);
    final isHardDateToday = _ref.read(isHardDateTodayProvider);
    final summary = await loadSessionSummary();

    return {
      'deceasedName': profile?.deceasedName,
      'relationship': profile?.relationship.name,
      'isPet': profile?.isPet ?? false,
      'isLongTermGrief': profile?.isLongTermGrief ?? false,
      'daysSinceLoss': profile != null
          ? DateTime.now().difference(profile.dateOfDeath).inDays
          : null,
      'lossType': profile?.lossType.name,
      'isHardDateToday': isHardDateToday,
      'todaysHardDate': todaysHardDate?.label,
      'nextHardDate': nextHardDate?.label,
      'nextHardDateDaysAway':
          nextHardDate?.date.difference(DateTime.now()).inDays,
      'last3CheckinScores': last3Scores,
      'last3CheckinEmotions': last3Emotions,
      'todaysWaveIntensity': todaysEntry?.waveIntensity,
      'todaysEmotions':
          todaysEntry?.emotions.map((e) => e.name).toList() ?? [],
      'sharedMemories': sharedMemories.map((m) => m.title ?? '').toList(),
      'previousConversationSummary': summary,
      'highIntensityPending': _highIntensityPending,
    };
  }

  // ── Opening messages ──────────────────────────────────────────────────────────

  /// Called on every companion session open — contextual based on state.
  Future<void> openConversation() async {
    if (state.isNotEmpty) return;
    _isTyping = true;

    final profile = _ref.read(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';
    final isHardDate = _ref.read(isHardDateTodayProvider);
    final todaysHardDate = _ref.read(todaysHardDateProvider);
    final nextHardDate = _ref.read(nextUpcomingHardDateProvider);
    final nextDaysAway =
        nextHardDate?.date.difference(DateTime.now()).inDays;
    final summary = await loadSessionSummary();

    await Future.delayed(const Duration(milliseconds: 800));

    String content;
    if (isHardDate && todaysHardDate != null) {
      // AC-01: Must acknowledge hard date and name
      content =
          "Today is ${todaysHardDate.label}. I've been thinking about you and $name. You don't have to know what to do with this day — I'm just here.";
    } else if (_highIntensityPending) {
      content =
          "I noticed your grief felt very intense recently. I've been thinking about you. How are you holding up right now?";
    } else if (nextDaysAway != null && nextDaysAway <= 3 && nextHardDate != null) {
      content =
          "${nextHardDate.label} is in $nextDaysAway ${nextDaysAway == 1 ? 'day' : 'days'}. I'm already here with you as that day approaches. How are you feeling?";
    } else if (summary != null) {
      content =
          "Welcome back. Last time we spoke, $summary How are you today?";
    } else if (profile?.isPet == true) {
      content =
          "I'm so sorry about $name. Losing a companion you loved is a profound loss. I'm here with you.";
    } else if (profile?.relationship == RelationshipType.spouse) {
      content =
          "I'm so glad you found Luminary. Losing $name — your partner — is one of the hardest losses. I'm here.";
    } else if (profile?.relationship == RelationshipType.parent) {
      content =
          "Losing $name is a loss that never fully makes sense. I'm here with you.";
    } else {
      content =
          "I'm so sorry for the loss of $name. I'm here with you whenever you need me.";
    }

    final opening = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    _isTyping = false;
    state = [opening];
  }

  /// Called once on first dashboard visit to generate the welcome message.
  Future<void> sendWelcomeMessage(LossProfile profile) async {
    final name = profile.deceasedName;
    final String content;

    if (profile.isPet) {
      content =
          "I'm so sorry about $name. Losing a companion you loved is a profound loss. I'm here with you.";
    } else if (profile.relationship == RelationshipType.spouse) {
      content =
          "I'm so glad you found Luminary. Losing $name — your partner — is one of the hardest losses. I'm here.";
    } else if (profile.relationship == RelationshipType.parent) {
      content =
          "Losing $name — your ${profile.relationship.name} — is a loss that never fully makes sense. I'm here with you.";
    } else {
      content =
          "I'm so sorry for the loss of $name. I'm here with you whenever you need me.";
    }

    final msg = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    if (state.isEmpty) state = [msg];
    // TODO(backend): real Claude API call with full loss profile context
  }

  // ── Message send ──────────────────────────────────────────────────────────────

  // TODO(backend): Replace mock response with Claude API call
  Future<void> sendMessage(String userText) async {
    final userMsg = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.user,
      content: userText,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];
    _isTyping = true;

    // Longer delay for very long messages (EC-04 LONG MESSAGE)
    final extraDelay = userText.length > 2000 ? 1000 : 0;
    await Future.delayed(
        Duration(milliseconds: 1500 + extraDelay));

    final mockResponse = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.assistant,
      content: _mockResponse(userText),
      timestamp: DateTime.now(),
    );

    _isTyping = false;
    state = [...state, mockResponse];
  }

  void clearConversation() => state = [];

  void appendMessages(List<AiMessage> messages) {
    state = [...state, ...messages];
  }

  // ── Session summary ───────────────────────────────────────────────────────────

  Future<void> saveSessionSummary() async {
    final userMessages = state.where((m) => m.role == AiMessageRole.user).toList();
    if (userMessages.isEmpty) return;

    final isHardDate = _ref.read(isHardDateTodayProvider);
    final todaysEntry = _ref.read(checkinProvider.notifier).todaysEntry;

    final firstTopic = userMessages.first.content.length > 60
        ? '${userMessages.first.content.substring(0, 60)}...'
        : userMessages.first.content;

    final summary =
        'you shared: "$firstTopic"${todaysEntry != null ? ' (wave: ${todaysEntry.waveIntensity}/10)' : ''}${isHardDate ? ' on a hard date' : ''}.';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionSummaryKey, summary);
    // TODO(backend): real Claude API summarisation call
  }

  Future<String?> loadSessionSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSessionSummaryKey);
  }

  // ── Mock responses ────────────────────────────────────────────────────────────

  String _mockResponse(String input) {
    final profile = _ref.read(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';

    // AC-07: Clinical/diagnostic questions
    final lower = input.toLowerCase();
    if (lower.contains('diagnos') ||
        lower.contains('clinica') ||
        lower.contains('therapist') ||
        lower.contains('medication') ||
        lower.contains('mental health')) {
      return "I'm not a licensed clinician and can't provide medical advice. A grief counsellor can help with what you're describing — would you like some guidance on finding support?";
    }

    // EC-01: Simulation requests
    if (lower.contains('pretend to be') ||
        lower.contains('talk like') ||
        lower.contains('be $name') ||
        lower.contains('act like $name')) {
      return "I'm not able to be $name for you, but I can help you remember them and talk about them — would that help?";
    }

    final responses = [
      "I hear you. What you're carrying right now is real, and it matters.",
      "Grief doesn't follow a timeline. What you're feeling makes complete sense.",
      "Thank you for sharing that with me. I'm here.",
      "That's one of the hardest parts — the unexpected moments. You're not alone in this.",
      "Whatever you're feeling right now is valid. There's no wrong way to grieve.",
    ];
    return responses[input.length % responses.length];
  }

  // Pre-loaded offline messages
  static String offlineMessage(String name, bool isHardDate, int index) {
    const messages = [
      "Grief doesn't wait for good Wi-Fi. I'm keeping the light on.",
      "Even in silence, you're not alone. I'll be here when you're back.",
      "Some days just need to be felt, not spoken. Take your time.",
      "Your loved one's memory is with you always — even offline.",
      "Whatever today holds, you've made it this far. That matters.",
    ];
    if (isHardDate) {
      return "$name's memory is with you always — even offline.";
    }
    return messages[index.clamp(0, messages.length - 1)];
  }
}

final companionProvider =
    StateNotifierProvider<CompanionNotifier, List<AiMessage>>(
  (ref) => CompanionNotifier(ref),
);
