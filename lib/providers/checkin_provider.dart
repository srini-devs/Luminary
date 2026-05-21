import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkin_entry.dart';

const _kCheckinKey = 'checkin_entries';

class CheckinNotifier extends StateNotifier<List<CheckinEntry>> {
  CheckinNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCheckinKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        state = list.map((j) => CheckinEntry.fromJson(j as Map<String, dynamic>)).toList();
        return;
      } catch (_) {}
    }
    // No mock data on init — loaded via MockDataService
    state = [];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCheckinKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  bool get isTodayCheckedIn {
    final todayDate = _dateOnly(DateTime.now());
    return state.any((e) => _dateOnly(e.date) == todayDate);
  }

  CheckinEntry? get todaysEntry {
    final todayDate = _dateOnly(DateTime.now());
    final todays = state.where((e) => _dateOnly(e.date) == todayDate).toList();
    if (todays.isEmpty) return null;
    // Return max intensity entry for today
    return todays.reduce((a, b) => a.waveIntensity >= b.waveIntensity ? a : b);
  }

  // Last N check-in scores (across all days, most recent first)
  List<int> get last3Scores {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(3).map((e) => e.waveIntensity).toList();
  }

  // Last N emotion lists (across all days, most recent first)
  List<List<String>> get last3Emotions {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(3).map((e) => e.emotions.map((em) => em.name).toList()).toList();
  }

  // Consecutive days with at least one check-in (ending today or yesterday)
  int get streakDays {
    if (state.isEmpty) return 0;
    final days = state.map((e) => _dateOnly(e.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak must include today or yesterday
    if (days.first != today && days.first != yesterday) return 0;

    int streak = 1;
    for (var i = 1; i < days.length; i++) {
      final expected = days[i - 1].subtract(const Duration(days: 1));
      if (days[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // TODO(backend): Sync checkin to Supabase after local save
  void saveCheckin(CheckinEntry entry) {
    // Store all entries (multiple per day allowed); deduplicate by id only
    state = [...state.where((e) => e.id != entry.id), entry];
    _persist();
  }

  void loadMockData(List<CheckinEntry> entries) {
    state = entries;
    _persist();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

final checkinProvider = StateNotifierProvider<CheckinNotifier, List<CheckinEntry>>(
  (ref) => CheckinNotifier(),
);

final isTodayCheckedInProvider = Provider<bool>((ref) {
  ref.watch(checkinProvider);
  return ref.read(checkinProvider.notifier).isTodayCheckedIn;
});

final todaysCheckinProvider = Provider<CheckinEntry?>((ref) {
  ref.watch(checkinProvider);
  return ref.read(checkinProvider.notifier).todaysEntry;
});
