import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grief_calendar_event.dart';

const _kCheckinReminderId = 1;
const _kNotifPermissionKey = 'notif_permission';
const _kNotifHardDateKey = 'notif_hard_date';
const _kNotifCheckinKey = 'notif_checkin';

final _flnPlugin = FlutterLocalNotificationsPlugin();

class NotificationState {
  final bool permissionGranted;
  final bool hardDateRemindersEnabled;
  final bool checkinRemindersEnabled;

  const NotificationState({
    this.permissionGranted = false,
    this.hardDateRemindersEnabled = true,
    this.checkinRemindersEnabled = true,
  });

  NotificationState copyWith({
    bool? permissionGranted,
    bool? hardDateRemindersEnabled,
    bool? checkinRemindersEnabled,
  }) {
    return NotificationState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      hardDateRemindersEnabled:
          hardDateRemindersEnabled ?? this.hardDateRemindersEnabled,
      checkinRemindersEnabled:
          checkinRemindersEnabled ?? this.checkinRemindersEnabled,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    _initPlugin();
    _loadFromPrefs();
  }

  Future<void> _initPlugin() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _flnPlugin.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionGranted = prefs.getBool(_kNotifPermissionKey) ?? false;
    final hardDateEnabled = prefs.getBool(_kNotifHardDateKey) ?? true;
    final checkinEnabled = prefs.getBool(_kNotifCheckinKey) ?? true;
    state = NotificationState(
      permissionGranted: permissionGranted,
      hardDateRemindersEnabled: hardDateEnabled,
      checkinRemindersEnabled: checkinEnabled,
    );
  }

  Future<void> requestPermission() async {
    bool granted = false;

    final iosPlugin = _flnPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    final androidPlugin = _flnPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      granted = result ?? false;
    }

    state = state.copyWith(permissionGranted: granted);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifPermissionKey, granted);
  }

  void toggleHardDateReminders() {
    final newValue = !state.hardDateRemindersEnabled;
    state = state.copyWith(hardDateRemindersEnabled: newValue);
    SharedPreferences.getInstance().then((p) => p.setBool(_kNotifHardDateKey, newValue));
  }

  void toggleCheckinReminders() {
    final newValue = !state.checkinRemindersEnabled;
    state = state.copyWith(checkinRemindersEnabled: newValue);
    SharedPreferences.getInstance().then((p) => p.setBool(_kNotifCheckinKey, newValue));
  }

  /// Schedule a 7 PM check-in reminder if not already past 7 PM.
  Future<void> scheduleCheckinReminder() async {
    if (!state.permissionGranted || !state.checkinRemindersEnabled) return;
    final now = DateTime.now();
    if (now.hour >= 19) return; // already past 7 PM

    await cancelCheckinReminder();
    // TODO(backend): await _flnPlugin.zonedSchedule(
    //   _kCheckinReminderId,
    //   'How are you feeling today?',
    //   'It only takes a moment.',
    //   tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0),
    //   const NotificationDetails(...),
    //   payload: 'type=checkin',
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //   uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    // );
  }

  Future<void> cancelCheckinReminder() async {
    await _flnPlugin.cancel(id: _kCheckinReminderId);
  }

  /// Schedule hard date notifications for events within the next 7 days.
  Future<void> scheduleHardDateNotifications(
      List<GriefCalendarEvent> events, String deceasedName) async {
    if (!state.permissionGranted || !state.hardDateRemindersEnabled) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = events.where((e) {
      final eventDay = DateTime(e.date.year, e.date.month, e.date.day);
      final daysUntil = eventDay.difference(today).inDays;
      return daysUntil >= 0 && daysUntil <= 7;
    }).toList();

    if (upcoming.length > 1) {
      // EC-MULTIPLE HARD DATES: single combined notification
      // TODO(backend): schedule combined notification:
      //   Title: "Three significant days are coming up."
      //   Body: "Tap to see your grief calendar."
      //   Payload: "type=calendar"
      return;
    }

    // TODO(backend): schedule notification via _flnPlugin.zonedSchedule for event
    // daysUntil=0 → 08:00 AM today, daysUntil=1 → 09:00 AM tomorrow,
    // daysUntil=3 → 09:00 AM three days before
    // Title: "$deceasedName's ${event.label} …"
    // Payload: 'type=hard_date&eventId=${event.id}'
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
