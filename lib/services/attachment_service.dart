import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/message_attachment.dart';

class AttachmentService {
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();

  Future<MessageAttachment?> pickTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'json', 'csv', 'log'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    String? text;
    if (file.bytes != null) {
      text = String.fromCharCodes(file.bytes!);
    } else if (file.path != null && !kIsWeb) {
      text = await File(file.path!).readAsString();
    }
    final preview = text != null && text.length > 4000
        ? '${text.substring(0, 4000)}…'
        : text;
    return MessageAttachment(
      id: _uuid.v4(),
      name: file.name,
      type: AttachmentType.textFile,
      localPath: file.path,
      textContent: preview,
    );
  }

  Future<MessageAttachment?> pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return MessageAttachment(
      id: _uuid.v4(),
      name: picked.name,
      type: AttachmentType.image,
      localPath: picked.path,
    );
  }

  /// Text blocks sent to the backend as extra context.
  List<String> buildAttachmentContext(List<MessageAttachment> attachments) {
    final blocks = <String>[];
    for (final a in attachments) {
      switch (a.type) {
        case AttachmentType.textFile:
          if (a.textContent != null && a.textContent!.trim().isNotEmpty) {
            blocks.add('File "${a.name}":\n${a.textContent}');
          } else {
            blocks.add('File attached: ${a.name} (no text extracted)');
          }
        case AttachmentType.image:
          blocks.add(
            'Image attached: ${a.name}. The user may want help related to this image.',
          );
        case AttachmentType.other:
          blocks.add('Attachment: ${a.name}');
      }
    }
    return blocks;
  }
}
