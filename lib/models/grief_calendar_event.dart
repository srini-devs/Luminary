enum CalendarEventType {
  milestone,
  deathAnniversary,
  birthdayOfDeceased,
  holiday,
  custom,
}

class GriefCalendarEvent {
  final String id;
  final String lossProfileId;
  final DateTime date;
  final CalendarEventType eventType;
  final String label;
  final bool isRecurring;
  final bool notificationsEnabled;
  final bool isPast;

  const GriefCalendarEvent({
    required this.id,
    required this.lossProfileId,
    required this.date,
    required this.eventType,
    required this.label,
    this.isRecurring = false,
    this.notificationsEnabled = true,
    required this.isPast,
  });
}
