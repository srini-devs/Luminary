import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final bool sessionActive;
  final bool onboardingComplete;
  final bool isLoaded;

  const AppState({
    required this.sessionActive,
    required this.onboardingComplete,
    this.isLoaded = false,
  });
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier()
      : super(const AppState(
          sessionActive: false,
          onboardingComplete: false,
          isLoaded: false,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppState(
      sessionActive: prefs.getBool('session_active') ?? false,
      onboardingComplete: prefs.getString('onboarding_complete') != null,
      isLoaded: true,
    );
  }

  Future<void> setSessionActive(bool value) async {
    // Update in-memory state immediately so router re-evaluates without async gap
    state = AppState(
      sessionActive: value,
      onboardingComplete: state.onboardingComplete,
      isLoaded: state.isLoaded,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session_active', value);
  }

  Future<void> setOnboardingComplete() async {
    // Update in-memory state immediately
    state = AppState(
      sessionActive: state.sessionActive,
      onboardingComplete: true,
      isLoaded: state.isLoaded,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_complete', 'true');
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);
