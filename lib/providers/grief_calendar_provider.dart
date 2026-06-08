import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/grief_calendar_event.dart';
import '../models/loss_profile.dart';
import 'loss_profile_provider.dart';

const _uuid = Uuid();

// ── Holiday date helpers ──────────────────────────────────────────────────────

DateTime _nthWeekdayOfMonth(int year, int month, int weekday, int n) {
  var d = DateTime(year, month, 1);
  var count = 0;
  while (true) {
    if (d.weekday == weekday) {
      count++;
      if (count == n) return d;
    }
    d = d.add(const Duration(days: 1));
  }
}

DateTime _holidayDate(HolidayType type, int year) {
  switch (type) {
    case HolidayType.christmas:
      return DateTime(year, 12, 25);
    case HolidayType.newYear:
      return DateTime(year, 1, 1);
    case HolidayType.mothersDay:
      // Second Sunday in May
      return _nthWeekdayOfMonth(year, 5, DateTime.sunday, 2);
    case HolidayType.fathersDay:
      // Third Sunday in June
      return _nthWeekdayOfMonth(year, 6, DateTime.sunday, 3);
    case HolidayType.thanksgiving:
      // Fourth Thursday in November (US)
      return _nthWeekdayOfMonth(year, 11, DateTime.thursday, 4);
    case HolidayType.easter:
      // Anonymous Gregorian algorithm
      final a = year % 19;
      final b = year ~/ 100;
      final c = year % 100;
      final d = b ~/ 4;
      final e = b % 4;
      final f = (b + 8) ~/ 25;
      final g = (b - f + 1) ~/ 3;
      final h = (19 * a + b - d - g + 15) % 30;
      final i = c ~/ 4;
      final k = c % 4;
      final l = (32 + 2 * e + 2 * i - h - k) % 7;
      final m = (a + 11 * h + 22 * l) ~/ 451;
      final month = (h + l - 7 * m + 114) ~/ 31;
      final day = ((h + l - 7 * m + 114) % 31) + 1;
      return DateTime(year, month, day);
    case HolidayType.diwali:
      // Approximate: third week of October/November (varies by Hindu calendar)
      // Using rough approximation: Nov 1 ± 15 days — simplified to Oct 20 for mock
      return DateTime(year, 10, 20);
    case HolidayType.eid:
      // Approximate: Islamic lunar calendar shifts ~11 days/year
      // Mock: June 17 as approximate Eid al-Fitr
      return DateTime(year, 6, 17);
    case HolidayType.custom:
      return DateTime(year, 1, 1);
  }
}

String _holidayLabel(HolidayType type) {
  switch (type) {
    case HolidayType.christmas:
      return 'Christmas';
    case HolidayType.newYear:
      return "New Year's";
    case HolidayType.mothersDay:
      return "Mother's Day";
    case HolidayType.fathersDay:
      return "Father's Day";
    case HolidayType.thanksgiving:
      return 'Thanksgiving';
    case HolidayType.easter:
      return 'Easter';
    case HolidayType.diwali:
      return 'Diwali';
    case HolidayType.eid:
      return 'Eid';
    case HolidayType.custom:
      return 'Special day';
  }
}

// ── Anniversary date with leap year handling ──────────────────────────────────

DateTime _anniversaryDate(DateTime dod, int yearsAhead) {
  int year = dod.year + yearsAhead;
  int month = dod.month;
  int day = dod.day;

  // Leap year edge case: Feb 29 → Feb 28 in non-leap years
  if (month == 2 && day == 29) {
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    if (!isLeap) day = 28;
  }
  return DateTime(year, month, day);
}

// ── Main event computation ────────────────────────────────────────────────────

List<GriefCalendarEvent> _computeEvents(LossProfile profile) {
  final dod = profile.dateOfDeath;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final events = <GriefCalendarEvent>[];

  void addMilestone(Duration offset, String label) {
    final date = DateTime(dod.year, dod.month, dod.day).add(offset);
    events.add(GriefCalendarEvent(
      id: _uuid.v4(),
      lossProfileId: profile.id,
      date: date,
      eventType: CalendarEventType.milestone,
      label: label,
      isRecurring: false,
      isPast: date.isBefore(today),
    ));
  }

  addMilestone(const Duration(days: 7), '1-week anniversary');
  addMilestone(const Duration(days: 30), '1-month anniversary');
  addMilestone(const Duration(days: 91), '3-month anniversary');
  addMilestone(const Duration(days: 182), '6-month anniversary');
  addMilestone(const Duration(days: 365), '1-year anniversary');
  addMilestone(const Duration(days: 548), '18-month anniversary');
  addMilestone(const Duration(days: 730), '2-year anniversary');

  // Annual death anniversary (recurring, up to 5 years)
  final isLeapDeath = dod.month == 2 && dod.day == 29;
  for (var year = 1; year <= 5; year++) {
    final date = _anniversaryDate(dod, year);
    final label = '${_ordinal(year)}-year anniversary'
        '${isLeapDeath && date.day == 28 ? ' (Feb 28 — anniversary defaults to Feb 28 in non-leap years)' : ''}';
    events.add(GriefCalendarEvent(
      id: _uuid.v4(),
      lossProfileId: profile.id,
      date: date,
      eventType: CalendarEventType.deathAnniversary,
      label: label,
      isRecurring: true,
      isPast: date.isBefore(today),
    ));
  }

  // Birthday of deceased (annually for 3 years forward)
  if (profile.dateOfBirth != null) {
    for (var year = 0; year <= 3; year++) {
      final dob = profile.dateOfBirth!;
      final date = DateTime(now.year + year, dob.month, dob.day);
      events.add(GriefCalendarEvent(
        id: _uuid.v4(),
        lossProfileId: profile.id,
        date: date,
        eventType: CalendarEventType.birthdayOfDeceased,
        label: "${profile.deceasedName}'s birthday",
        isRecurring: true,
        isPast: date.isBefore(today),
      ));
    }
  }

  // User-tracked holidays: compute next occurrence, label as "First/Second"
  for (final holiday in profile.trackedHolidays) {
    final name = profile.deceasedName;
    final holidayName = _holidayLabel(holiday);
    final thisYearDate = _holidayDate(holiday, now.year);
    final thisYearDay = DateTime(thisYearDate.year, thisYearDate.month, thisYearDate.day);

    if (thisYearDay.isAfter(today) || thisYearDay == today) {
      // Holiday hasn't happened yet this year — first occurrence without [Name]
      events.add(GriefCalendarEvent(
        id: _uuid.v4(),
        lossProfileId: profile.id,
        date: thisYearDate,
        eventType: CalendarEventType.holiday,
        label: 'First $holidayName without $name',
        isRecurring: true,
        isPast: false,
      ));
    } else {
      // Holiday already passed this year — next occurrence is next year → second
      final nextYearDate = _holidayDate(holiday, now.year + 1);
      events.add(GriefCalendarEvent(
        id: _uuid.v4(),
        lossProfileId: profile.id,
        date: nextYearDate,
        eventType: CalendarEventType.holiday,
        label: 'Second $holidayName without $name',
        isRecurring: true,
        isPast: false,
      ));
    }
  }

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
}

String _ordinal(int n) {
  if (n == 1) return '1st';
  if (n == 2) return '2nd';
  if (n == 3) return '3rd';
  return '${n}th';
}

// ── Providers ─────────────────────────────────────────────────────────────────

final griefCalendarProvider = Provider<List<GriefCalendarEvent>>((ref) {
  final profile = ref.watch(lossProfileProvider);
  if (profile == null) return [];
  return _computeEvents(profile);
});

final isHardDateTodayProvider = Provider<bool>((ref) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return ref.watch(allCalendarEventsProvider).any((e) {
    final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
    return eventDate == todayDate;
  });
});

final todaysHardDateProvider = Provider<GriefCalendarEvent?>((ref) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final events = ref.watch(allCalendarEventsProvider);
  try {
    return events.firstWhere((e) {
      final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
      return eventDate == todayDate;
    });
  } catch (_) {
    return null;
  }
});

final nextUpcomingHardDateProvider = Provider<GriefCalendarEvent?>((ref) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final events = ref
      .watch(allCalendarEventsProvider)
      .where((e) => !DateTime(e.date.year, e.date.month, e.date.day).isBefore(todayDate));
  if (events.isEmpty) return null;
  return events.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
});

final next3HardDatesProvider = Provider<List<GriefCalendarEvent>>((ref) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final events = ref
      .watch(allCalendarEventsProvider)
      .where((e) => !DateTime(e.date.year, e.date.month, e.date.day).isBefore(todayDate))
      .toList();
  return events.take(3).toList();
});

// ── Custom user-added events ──────────────────────────────────────────────────

class CustomCalendarEventsNotifier
    extends StateNotifier<List<GriefCalendarEvent>> {
  CustomCalendarEventsNotifier() : super([]);

  void addCustomEvent(GriefCalendarEvent event) {
    state = [...state, event];
  }

  void removeCustomEvent(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final customCalendarEventsProvider = StateNotifierProvider<
    CustomCalendarEventsNotifier, List<GriefCalendarEvent>>(
  (ref) => CustomCalendarEventsNotifier(),
);

/// Merges computed grief events + user-added custom events, sorted by date.
final allCalendarEventsProvider = Provider<List<GriefCalendarEvent>>((ref) {
  final computed = ref.watch(griefCalendarProvider);
  final custom = ref.watch(customCalendarEventsProvider);
  final combined = [...computed, ...custom];
  combined.sort((a, b) => a.date.compareTo(b.date));
  return combined;
});
