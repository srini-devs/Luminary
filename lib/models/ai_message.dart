enum AiMessageRole { user, assistant }

class AiMessage {
  final String id;
  final AiMessageRole role;
  final String content;
  final DateTime timestamp;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.index,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
        id: j['id'] as String,
        role: AiMessageRole.values[j['role'] as int],
        content: j['content'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}
