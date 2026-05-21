enum SubscriptionStatus { trial, active, cancelled, expired, gracePeriod }

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? trialEndDate;
  final bool notificationsEnabled;
  final bool reducedMotion;
  final bool largerText;
  final bool trialExtendedOnce;
  final String? fcmToken;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.subscriptionStatus,
    this.trialEndDate,
    this.notificationsEnabled = false,
    this.reducedMotion = false,
    this.largerText = false,
    this.trialExtendedOnce = false,
    this.fcmToken,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    SubscriptionStatus? subscriptionStatus,
    DateTime? trialEndDate,
    bool? notificationsEnabled,
    bool? reducedMotion,
    bool? largerText,
    bool? trialExtendedOnce,
    String? fcmToken,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      largerText: largerText ?? this.largerText,
      trialExtendedOnce: trialExtendedOnce ?? this.trialExtendedOnce,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'subscriptionStatus': subscriptionStatus.index,
        'trialEndDate': trialEndDate?.toIso8601String(),
        'notificationsEnabled': notificationsEnabled,
        'reducedMotion': reducedMotion,
        'largerText': largerText,
        'trialExtendedOnce': trialExtendedOnce,
        'fcmToken': fcmToken,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String,
        subscriptionStatus: SubscriptionStatus
            .values[(j['subscriptionStatus'] as int?) ?? 0],
        trialEndDate: j['trialEndDate'] != null
            ? DateTime.parse(j['trialEndDate'] as String)
            : null,
        notificationsEnabled: (j['notificationsEnabled'] as bool?) ?? false,
        reducedMotion: (j['reducedMotion'] as bool?) ?? false,
        largerText: (j['largerText'] as bool?) ?? false,
        trialExtendedOnce: (j['trialExtendedOnce'] as bool?) ?? false,
        fcmToken: j['fcmToken'] as String?,
      );
}
