import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    state = _isOnline(results);
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !state;
      state = _isOnline(results);
      if (wasOffline && state) {
        SyncService.syncOnReconnect();
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);

final isOfflineProvider = Provider<bool>((ref) {
  return !ref.watch(connectivityProvider);
});
