import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

const _kUserProfileKey = 'user_profile';

// TODO(backend): Replace mock with Supabase auth session check
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    _loadFromPrefs();
  }

  static final _mockUser = UserProfile(
    id: 'mock-sarah-001',
    email: '',
    displayName: 'Sarah Mitchell',
    subscriptionStatus: SubscriptionStatus.active,
  );

  bool get isLoggedIn => state != null;
  bool get isSubscribed =>
      state?.subscriptionStatus == SubscriptionStatus.active ||
      state?.subscriptionStatus == SubscriptionStatus.trial;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserProfileKey);
    UserProfile? loaded;
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        loaded = UserProfile.fromJson(map);
      } catch (_) {}
    }
    loaded ??= _mockUser;

    // Override email with whatever the user actually typed at sign-in/sign-up
    final savedEmail = prefs.getString('user_email') ?? '';
    if (savedEmail.isNotEmpty && loaded.email != savedEmail) {
      loaded = loaded.copyWith(email: savedEmail);
    }

    state = loaded;
    if (raw == null || savedEmail.isNotEmpty) _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (state != null) {
      await prefs.setString(_kUserProfileKey, jsonEncode(state!.toJson()));
    } else {
      await prefs.remove(_kUserProfileKey);
    }
  }

  // TODO(backend): Call Supabase signOut
  void signOut() {
    state = null;
    _persist();
  }

  // TODO(backend): Update user profile in Supabase
  void updateProfile(UserProfile profile) {
    state = profile;
    _persist();
  }

  void toggleReducedMotion() {
    state = state?.copyWith(reducedMotion: !(state?.reducedMotion ?? false));
    _persist();
  }

  void toggleLargerText() {
    state = state?.copyWith(largerText: !(state?.largerText ?? false));
    _persist();
  }

  // One-time 3-day trial extension (guarded by trialExtendedOnce)
  bool get canExtendTrial =>
      state?.subscriptionStatus == SubscriptionStatus.trial &&
      !(state?.trialExtendedOnce ?? true);

  void extendTrial() {
    if (!canExtendTrial) return;
    final newEnd =
        (state?.trialEndDate ?? DateTime.now()).add(const Duration(days: 3));
    state = state?.copyWith(trialEndDate: newEnd, trialExtendedOnce: true);
    _persist();
  }

  void setSubscriptionStatus(SubscriptionStatus status) {
    state = state?.copyWith(subscriptionStatus: status);
    _persist();
    // TODO(backend): Update subscription status in Supabase + RevenueCat
  }

  void storeFcmToken(String token) {
    state = state?.copyWith(fcmToken: token);
    _persist();
    // TODO(backend): POST fcmToken to Supabase user record for push targeting
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);
