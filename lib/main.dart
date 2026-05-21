import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'router/app_router.dart';

// TODO(backend): Uncomment after adding google-services.json (Android)
// and GoogleService-Info.plist (iOS) to their respective platform folders.
// import 'package:firebase_core/firebase_core.dart';
// import 'services/fcm_service.dart';

@pragma('vm:entry-point')
void _onNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;

  final params = Uri.splitQueryString(payload);
  final type = params['type'];

  final nav = navigatorKey.currentState;
  if (nav == null) return;

  if (type == 'checkin') {
    nav.pushNamed('/checkin');
  } else if (type == 'hard_date') {
    nav.pushNamed('/calendar');
  } else if (type == 'calendar') {
    nav.pushNamed('/calendar');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(backend): await Firebase.initializeApp();
  // FCM routing is wired in FcmService.listenForRouting(router)
  // called from LuminaryApp after GoRouter is ready.

  // Wire local notification tap handler
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await FlutterLocalNotificationsPlugin().initialize(
    settings: const InitializationSettings(
        android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: _onNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    const ProviderScope(
      child: LuminaryApp(),
    ),
  );
}
