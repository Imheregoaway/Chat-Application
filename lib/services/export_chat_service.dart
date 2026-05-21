import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ai_message.dart';

class ExportChatService {
  String toMarkdown(List<AiMessage> messages, {String? title}) {
    final buffer = StringBuffer();
    buffer.writeln('# ${title ?? 'AI Chat Export'}');
    buffer.writeln();
    buffer.writeln('_Exported ${DateFormat.yMMMd().add_jm().format(DateTime.now())}_');
    buffer.writeln();

    for (final m in messages) {
      if (m.isStreaming || m.content.trim().isEmpty) continue;
      final role = m.isUser ? 'You' : 'Assistant';
      final time = DateFormat.jm().format(m.timestamp);
      buffer.writeln('## $role · $time');
      buffer.writeln();
      if (m.attachments.isNotEmpty) {
        for (final a in m.attachments) {
          buffer.writeln('> 📎 ${a.name}');
        }
        buffer.writeln();
      }
      buffer.writeln(m.content.trim());
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  Future<void> copyAll(List<AiMessage> messages) async {
    await Clipboard.setData(ClipboardData(text: toMarkdown(messages)));
  }

  Future<void> shareMarkdown(List<AiMessage> messages, {String? title}) async {
    final md = toMarkdown(messages, title: title);
    await Share.share(md, subject: title ?? 'AI Chat');
  }
}
