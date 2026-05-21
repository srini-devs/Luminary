class MemoryEntry {
  final String id;
  final String lossProfileId;
  final String? title;
  final String? textContent;
  final String? photoUrl;
  final String? localPhotoPath;
  final String? voiceNoteUrl;
  final bool isSharedWithAI;
  final DateTime addedAt;

  const MemoryEntry({
    required this.id,
    required this.lossProfileId,
    this.title,
    this.textContent,
    this.photoUrl,
    this.localPhotoPath,
    this.voiceNoteUrl,
    this.isSharedWithAI = false,
    required this.addedAt,
  });

  MemoryEntry copyWith({
    String? id,
    String? lossProfileId,
    String? title,
    String? textContent,
    String? photoUrl,
    String? localPhotoPath,
    String? voiceNoteUrl,
    bool? isSharedWithAI,
    DateTime? addedAt,
  }) {
    return MemoryEntry(
      id: id ?? this.id,
      lossProfileId: lossProfileId ?? this.lossProfileId,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      isSharedWithAI: isSharedWithAI ?? this.isSharedWithAI,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lossProfileId': lossProfileId,
        'title': title,
        'textContent': textContent,
        'photoUrl': photoUrl,
        'localPhotoPath': localPhotoPath,
        'voiceNoteUrl': voiceNoteUrl,
        'isSharedWithAI': isSharedWithAI,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MemoryEntry.fromJson(Map<String, dynamic> j) => MemoryEntry(
        id: j['id'] as String,
        lossProfileId: j['lossProfileId'] as String,
        title: j['title'] as String?,
        textContent: j['textContent'] as String?,
        photoUrl: j['photoUrl'] as String?,
        localPhotoPath: j['localPhotoPath'] as String?,
        voiceNoteUrl: j['voiceNoteUrl'] as String?,
        isSharedWithAI: (j['isSharedWithAI'] as bool?) ?? false,
        addedAt: DateTime.parse(j['addedAt'] as String),
      );
}
