enum RelationshipType { spouse, parent, child, sibling, friend, pet, other }

enum LossType { sudden, expected }

enum HolidayType {
  christmas,
  thanksgiving,
  mothersDay,
  fathersDay,
  easter,
  diwali,
  eid,
  newYear,
  custom,
}

class LossProfile {
  final String id;
  final String deceasedName;
  final RelationshipType relationship;
  final String? personalDescription;
  final DateTime dateOfDeath;
  final DateTime? dateOfBirth;
  final List<HolidayType> trackedHolidays;
  final LossType lossType;
  final bool isPet;
  final bool isLongTermGrief;

  const LossProfile({
    required this.id,
    required this.deceasedName,
    required this.relationship,
    this.personalDescription,
    required this.dateOfDeath,
    this.dateOfBirth,
    this.trackedHolidays = const [],
    required this.lossType,
    this.isPet = false,
    this.isLongTermGrief = false,
  });

  LossProfile copyWith({
    String? id,
    String? deceasedName,
    RelationshipType? relationship,
    String? personalDescription,
    DateTime? dateOfDeath,
    DateTime? dateOfBirth,
    List<HolidayType>? trackedHolidays,
    LossType? lossType,
    bool? isPet,
    bool? isLongTermGrief,
  }) {
    return LossProfile(
      id: id ?? this.id,
      deceasedName: deceasedName ?? this.deceasedName,
      relationship: relationship ?? this.relationship,
      personalDescription: personalDescription ?? this.personalDescription,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      trackedHolidays: trackedHolidays ?? this.trackedHolidays,
      lossType: lossType ?? this.lossType,
      isPet: isPet ?? this.isPet,
      isLongTermGrief: isLongTermGrief ?? this.isLongTermGrief,
    );
  }
}
