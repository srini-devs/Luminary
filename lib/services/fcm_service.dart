import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_profile_provider.dart';

/// Top-level background message handler — must be a top-level function.
/// TODO(backend): implement full background processing (local notification, badge)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(
    RemoteMessage message) async {
  // TODO(backend): await Firebase.initializeApp(); // re-initialize in isolate
  // TODO(backend): FlutterLocalNotificationsPlugin().show(...)
}

class FcmService {
  final Ref _ref;
  FcmService(this._ref);

  /// Call after Firebase.initializeApp() in main().
  Future<void> initialize() async {
    // TODO(backend): await Firebase.initializeApp();
    // TODO(backend): FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    // Request notification permission
    // TODO(backend): await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Store FCM token in UserProfileProvider for push targeting
    // TODO(backend): final token = await FirebaseMessaging.instance.getToken();
    // TODO(backend): if (token != null) _storeToken(token);

    // Refresh token listener
    // TODO(backend): FirebaseMessaging.instance.onTokenRefresh.listen(_storeToken);
  }

  // ignore: unused_element
  void _storeToken(String token) {
    _ref.read(userProfileProvider.notifier).storeFcmToken(token);
  }

  /// Wire up deep-link routing for when the user taps a notification.
  /// Call once from the root widget after GoRouter is ready.
  ///
  /// Supported payload `type` values:
  ///   "hard_date"        → /hard-date
  ///   "checkin"          → /checkin
  ///   "community_reply"  → /home/community/post/{postId}
  void listenForRouting(GoRouter router) {
    // App opened from terminated state via notification tap
    // TODO(backend): FirebaseMessaging.instance.getInitialMessage().then((message) {
    //   if (message != null) routeFromMessage(router, message);
    // });

    // App in background, user taps notification
    // TODO(backend): FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   routeFromMessage(router, message);
    // });

    // App in foreground — show in-app banner instead of push
    // TODO(backend): FirebaseMessaging.onMessage.listen(_showInAppBanner);
  }

  /// Parse a [RemoteMessage] payload and navigate to the correct screen.
  void routeFromMessage(GoRouter router, RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    switch (type) {
      case 'hard_date':
        router.go('/hard-date');
      case 'checkin':
        router.go('/checkin');
      case 'community_reply':
        final postId = data['postId'] as String? ?? '';
        router.go('/home/community/post/$postId');
      default:
        router.go('/home/dashboard');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>(
  (ref) => FcmService(ref),
);
