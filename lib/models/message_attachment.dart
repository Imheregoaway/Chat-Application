enum AttachmentType { image, textFile, other }

class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.name,
    required this.type,
    this.localPath,
    this.textContent,
  });

  final String id;
  final String name;
  final AttachmentType type;
  final String? localPath;
  final String? textContent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'localPath': localPath,
        'textContent': textContent,
      };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AttachmentType.other,
      ),
      localPath: json['localPath'] as String?,
      textContent: json['textContent'] as String?,
    );
  }
}
