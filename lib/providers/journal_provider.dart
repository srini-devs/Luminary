import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';

const _juuid = Uuid();
const _kJournalKey = 'journal_entries';

List<JournalEntry> _defaultMockEntries() {
  final now = DateTime.now();
  return [
    JournalEntry(id: _juuid.v4(), date: now, title: 'Today', content: 'I woke up and for a moment forgot she was gone. Then it came back.', waveIntensityAtTime: 5, intensityLevel: JournalIntensityLevel.gentle),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 2)), title: 'Six months', content: 'Half a year. I never thought I could carry this and I am.', waveIntensityAtTime: 7, intensityLevel: JournalIntensityLevel.moderate, isHardDate: true, isFavourite: true),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 7)), title: 'Something she would have loved', content: 'The garden is blooming exactly the way she used to describe.', waveIntensityAtTime: 3, intensityLevel: JournalIntensityLevel.gentle, isFavourite: true),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 10)), title: 'I got angry today', content: "I don't know who I was angry at.", waveIntensityAtTime: 8, intensityLevel: JournalIntensityLevel.high),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 14)), title: 'Her birthday is coming', content: 'March 12th is three weeks away.', waveIntensityAtTime: 6, intensityLevel: JournalIntensityLevel.moderate),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 18)), title: 'A small moment of peace', content: 'I made her recipe for the first time.', waveIntensityAtTime: 4, intensityLevel: JournalIntensityLevel.gentle),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 22)), title: 'Going through her things', content: 'I opened her wardrobe today.', waveIntensityAtTime: 8, intensityLevel: JournalIntensityLevel.high),
    JournalEntry(id: _juuid.v4(), date: now.subtract(const Duration(days: 25)), title: 'The first Monday', content: 'Eleanor always called on Mondays.', waveIntensityAtTime: 7, intensityLevel: JournalIntensityLevel.moderate),
  ];
}

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kJournalKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        state = list.map((j) => JournalEntry.fromJson(j as Map<String, dynamic>)).toList();
        return;
      } catch (_) {}
    }
    state = _defaultMockEntries();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kJournalKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  // TODO(backend): Sync journal entry to Supabase
  void addEntry(JournalEntry entry) {
    state = [entry, ...state];
    _persist();
  }

  // TODO(backend): Delete entry from Supabase
  void removeEntry(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  // TODO(backend): Update entry in Supabase
  void updateEntry(JournalEntry updated) {
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
    _persist();
  }

  void toggleFavourite(String id) {
    state = state.map((e) => e.id == id ? e.copyWith(isFavourite: !e.isFavourite) : e).toList();
    _persist();
  }

  void updateSharedWithAI(String id, bool shared) {
    state = state.map((e) => e.id == id ? e.copyWith(isSharedWithAI: shared) : e).toList();
    _persist();
  }

  void loadMockData(List<JournalEntry> entries) {
    state = entries;
    _persist();
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) => JournalNotifier());
