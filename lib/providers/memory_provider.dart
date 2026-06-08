import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_entry.dart';

const _muuid = Uuid();
const _kMemoryKey = 'memory_entries';

List<MemoryEntry> _defaultMockEntries() {
  final now = DateTime.now();
  return [
    MemoryEntry(
      id: _muuid.v4(),
      lossProfileId: 'loss-sarah-001',
      title: 'Her laugh',
      textContent: 'Eleanor had this specific laugh when something caught her off guard. A real laugh, not polite.',
      addedAt: now.subtract(const Duration(days: 2)),
      isSharedWithAI: true,
    ),
    MemoryEntry(
      id: _muuid.v4(),
      lossProfileId: 'loss-sarah-001',
      title: 'The garden',
      textContent: 'Every Sunday morning she would be in the garden by 7am. Tulips first, then roses.',
      addedAt: now.subtract(const Duration(days: 5)),
      isSharedWithAI: true,
    ),
    MemoryEntry(
      id: _muuid.v4(),
      lossProfileId: 'loss-sarah-001',
      title: 'Her recipe',
      textContent: 'Three cups of flour, two eggs — she never wrote it down. I had to rebuild it from memory.',
      addedAt: now.subtract(const Duration(days: 8)),
      isSharedWithAI: false,
    ),
    MemoryEntry(
      id: _muuid.v4(),
      lossProfileId: 'loss-sarah-001',
      title: 'Last Christmas',
      textContent: "We didn't know it would be the last one. She wore the red jumper I gave her.",
      addedAt: now.subtract(const Duration(days: 12)),
      isSharedWithAI: false,
    ),
    MemoryEntry(
      id: _muuid.v4(),
      lossProfileId: 'loss-sarah-001',
      title: 'What she always said',
      textContent: "Whenever I was worried she would say 'You've faced harder things than this, love.'",
      addedAt: now.subtract(const Duration(days: 20)),
      isSharedWithAI: true,
    ),
  ];
}

class MemoryNotifier extends StateNotifier<List<MemoryEntry>> {
  MemoryNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMemoryKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        state = list.map((j) => MemoryEntry.fromJson(j as Map<String, dynamic>)).toList();
        return;
      } catch (_) {}
    }
    state = _defaultMockEntries();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMemoryKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  // TODO(backend): Upload and sync memory to Supabase storage
  void addMemory(MemoryEntry memory) {
    state = [memory, ...state];
    _persist();
  }

  // TODO(backend): Delete memory from Supabase
  void removeMemory(String id) {
    state = state.where((m) => m.id != id).toList();
    _persist();
  }

  // TODO(backend): Update memory in Supabase
  void updateMemory(MemoryEntry updated) {
    state = state.map((m) => m.id == updated.id ? updated : m).toList();
    _persist();
  }

  void updateSharedWithAI(String id, bool shared) {
    state = state.map((m) => m.id == id ? m.copyWith(isSharedWithAI: shared) : m).toList();
    _persist();
  }

  void loadMockData(List<MemoryEntry> entries) {
    state = entries;
    _persist();
  }
}

final memoryProvider = StateNotifierProvider<MemoryNotifier, List<MemoryEntry>>((ref) => MemoryNotifier());
