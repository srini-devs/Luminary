enum JournalIntensityLevel { gentle, moderate, high }

class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final String? promptUsed;
  final int waveIntensityAtTime;
  final bool isHardDate;
  final JournalIntensityLevel intensityLevel;
  final bool isSharedWithAI;
  final bool isFavourite;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.promptUsed,
    required this.waveIntensityAtTime,
    this.isHardDate = false,
    required this.intensityLevel,
    this.isSharedWithAI = false,
    this.isFavourite = false,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    String? promptUsed,
    int? waveIntensityAtTime,
    bool? isHardDate,
    JournalIntensityLevel? intensityLevel,
    bool? isSharedWithAI,
    bool? isFavourite,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      promptUsed: promptUsed ?? this.promptUsed,
      waveIntensityAtTime: waveIntensityAtTime ?? this.waveIntensityAtTime,
      isHardDate: isHardDate ?? this.isHardDate,
      intensityLevel: intensityLevel ?? this.intensityLevel,
      isSharedWithAI: isSharedWithAI ?? this.isSharedWithAI,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'content': content,
        'promptUsed': promptUsed,
        'waveIntensityAtTime': waveIntensityAtTime,
        'isHardDate': isHardDate,
        'intensityLevel': intensityLevel.index,
        'isSharedWithAI': isSharedWithAI,
        'isFavourite': isFavourite,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        title: j['title'] as String,
        content: j['content'] as String,
        promptUsed: j['promptUsed'] as String?,
        waveIntensityAtTime: (j['waveIntensityAtTime'] as int?) ?? 5,
        isHardDate: (j['isHardDate'] as bool?) ?? false,
        intensityLevel:
            JournalIntensityLevel.values[(j['intensityLevel'] as int?) ?? 0],
        isSharedWithAI: (j['isSharedWithAI'] as bool?) ?? false,
        isFavourite: (j['isFavourite'] as bool?) ?? false,
      );
}
