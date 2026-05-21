import 'message_attachment.dart';

enum AiMessageRole { user, assistant }

class AiMessage {
  const AiMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
    this.attachments = const [],
  });

  final String id;
  final String content;
  final AiMessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final List<MessageAttachment> attachments;

  bool get isUser => role == AiMessageRole.user;

  AiMessage copyWith({
    String? id,
    String? content,
    AiMessageRole? role,
    DateTime? timestamp,
    bool? isStreaming,
    List<MessageAttachment>? attachments,
  }) {
    return AiMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        'isStreaming': isStreaming,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: AiMessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AiMessageRole.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isStreaming: json['isStreaming'] as bool? ?? false,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
