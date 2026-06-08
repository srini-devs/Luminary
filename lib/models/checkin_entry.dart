enum EmotionType {
  heavy,
  missing,
  angry,
  numb,
  grateful,
  lonely,
  peaceful,
  exhausted,
  hopeful,
  sad,
  confused,
  disconnected,
}

class CheckinEntry {
  final String id;
  final DateTime date;
  final int waveIntensity;
  final List<EmotionType> emotions;
  final String? note;
  final bool isHardDate;
  final bool isSyncedToServer;

  const CheckinEntry({
    required this.id,
    required this.date,
    required this.waveIntensity,
    required this.emotions,
    this.note,
    this.isHardDate = false,
    this.isSyncedToServer = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'waveIntensity': waveIntensity,
        'emotions': emotions.map((e) => e.index).toList(),
        'note': note,
        'isHardDate': isHardDate,
      };

  factory CheckinEntry.fromJson(Map<String, dynamic> j) => CheckinEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        waveIntensity: j['waveIntensity'] as int,
        emotions: (j['emotions'] as List<dynamic>)
            .map((i) => EmotionType.values[i as int])
            .toList(),
        note: j['note'] as String?,
        isHardDate: (j['isHardDate'] as bool?) ?? false,
      );
}
