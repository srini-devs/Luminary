import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loss_profile.dart';

const _kLossProfileKey = 'loss_profile_v1';
const _kOnboardingStep = 'onboarding_step';
const _kOnboardingComplete = 'onboarding_complete';

class LossProfileNotifier extends StateNotifier<LossProfile?> {
  LossProfileNotifier() : super(null) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kLossProfileKey);

    // Primary: full JSON blob saved at each onboarding step
    if (json != null) {
      try {
        // TODO(backend): Replace with Supabase fetch on login
        final map = jsonDecode(json) as Map<String, dynamic>;
        state = _fromMap(map);
        return;
      } catch (_) {}
    }

    // Fallback: reconstruct from individual onboarding keys
    final deceasedName = prefs.getString('deceased_name');
    if (deceasedName == null || deceasedName.isEmpty) return;

    final dateOfDeathStr = prefs.getString('date_of_death');
    if (dateOfDeathStr == null) return;
    final dateOfDeath = DateTime.tryParse(dateOfDeathStr);
    if (dateOfDeath == null) return;

    final relationshipStr = prefs.getString('relationship') ?? 'other';
    final relationship = RelationshipType.values.firstWhere(
      (e) => e.name == relationshipStr,
      orElse: () => RelationshipType.other,
    );

    final dateOfBirthStr = prefs.getString('date_of_birth');
    final dateOfBirth =
        dateOfBirthStr != null ? DateTime.tryParse(dateOfBirthStr) : null;

    List<HolidayType> trackedHolidays = [];
    final holidaysJson = prefs.getString('tracked_holidays');
    if (holidaysJson != null) {
      try {
        final list = jsonDecode(holidaysJson) as List;
        trackedHolidays = list
            .map((s) => HolidayType.values.firstWhere(
                  (e) => e.name == s.toString(),
                  orElse: () => HolidayType.christmas,
                ))
            .toList();
      } catch (_) {}
    }

    final lossTypeStr = prefs.getString('loss_type') ?? 'sudden';
    final lossType = LossType.values.firstWhere(
      (e) => e.name == lossTypeStr,
      orElse: () => LossType.sudden,
    );

    state = LossProfile(
      id: 'onboarding-profile',
      deceasedName: deceasedName,
      relationship: relationship,
      personalDescription: prefs.getString('personal_description'),
      dateOfDeath: dateOfDeath,
      dateOfBirth: dateOfBirth,
      trackedHolidays: trackedHolidays,
      lossType: lossType,
      isPet: relationship == RelationshipType.pet,
      isLongTermGrief:
          DateTime.now().difference(dateOfDeath).inDays / 365.0 >= 10,
    );
  }

  Future<void> saveLossProfile(LossProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLossProfileKey, jsonEncode(_toMap(profile)));
    // TODO(backend): Upsert loss profile to Supabase
  }

  Future<void> saveOnboardingStep(String step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOnboardingStep, step);
  }

  Future<void> saveOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOnboardingComplete, 'true');
    await prefs.remove(_kOnboardingStep);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLossProfileKey);
    await prefs.remove(_kOnboardingStep);
    await prefs.remove(_kOnboardingComplete);
  }

  LossProfile _fromMap(Map<String, dynamic> map) {
    return LossProfile(
      id: map['id'] as String,
      deceasedName: map['deceasedName'] as String,
      relationship: RelationshipType.values[map['relationship'] as int],
      personalDescription: map['personalDescription'] as String?,
      dateOfDeath: DateTime.parse(map['dateOfDeath'] as String),
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      trackedHolidays: (map['trackedHolidays'] as List)
          .map((i) => HolidayType.values[i as int])
          .toList(),
      lossType: LossType.values[map['lossType'] as int],
      isPet: map['isPet'] as bool? ?? false,
      isLongTermGrief: map['isLongTermGrief'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _toMap(LossProfile p) {
    return {
      'id': p.id,
      'deceasedName': p.deceasedName,
      'relationship': p.relationship.index,
      'personalDescription': p.personalDescription,
      'dateOfDeath': p.dateOfDeath.toIso8601String(),
      'dateOfBirth': p.dateOfBirth?.toIso8601String(),
      'trackedHolidays': p.trackedHolidays.map((h) => h.index).toList(),
      'lossType': p.lossType.index,
      'isPet': p.isPet,
      'isLongTermGrief': p.isLongTermGrief,
    };
  }
}

final lossProfileProvider =
    StateNotifierProvider<LossProfileNotifier, LossProfile?>(
  (ref) => LossProfileNotifier(),
);
