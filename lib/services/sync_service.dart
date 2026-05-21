// TODO(backend): Replace stubs with real Supabase sync calls

class SyncService {
  static Future<void> syncOnReconnect() async {
    await _syncCheckins();
    await _syncJournalEntries();
    await _syncMemories();
  }

  // TODO(backend): POST pending check-in entries to Supabase
  static Future<void> _syncCheckins() async {}

  // TODO(backend): POST pending journal entries to Supabase
  static Future<void> _syncJournalEntries() async {}

  // TODO(backend): POST pending memory entries to Supabase
  static Future<void> _syncMemories() async {}
}
