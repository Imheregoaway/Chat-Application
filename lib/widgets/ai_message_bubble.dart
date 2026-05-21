import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_accent_theme.dart';
import '../models/ai_message.dart';
import '../models/bubble_style.dart';
import '../models/message_attachment.dart';
import '../providers/locale_provider.dart';
import 'typing_indicator.dart';

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
    this.index = 0,
  });

  final AiMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        Theme.of(context).extension<AppAccentTheme>() ?? AppAccentTheme.defaultTheme();
    final isUser = message.isUser;
    final time = DateFormat.jm().format(message.timestamp);

    if (message.isStreaming) {
      return _AiTypingBubble(index: index, accent: accent);
    }

    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final content = isUser
        ? _userBubble(context, accent, isDark)
        : _assistantBubble(context, accent, isDark);

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 16,
        right: isUser ? 16 : 48,
        top: 6,
        bottom: 6,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          GestureDetector(
            onLongPress: () => _copyMessage(context, message.content),
            child: content,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              _CopyButton(
                onCopy: () => _copyMessage(context, message.content),
                color: isUser
                    ? accent.primary.withValues(alpha: 0.8)
                    : (isDark ? const Color(0xFF9E9EB8) : const Color(0xFF9E9EB8)),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: (index * 30).ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _userBubble(BuildContext context, AppAccentTheme accent, bool isDark) {
    final radius = _bubbleRadius(accent.bubbleStyle, isUser: true);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.primary, accent.primaryLight]),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accent.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.attachments.isNotEmpty) ...[
            ...message.attachments.map(_attachmentPreview),
            const SizedBox(height: 8),
          ],
          Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  Widget _assistantBubble(BuildContext context, AppAccentTheme accent, bool isDark) {
    final radius = _bubbleRadius(accent.bubbleStyle, isUser: false);
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachments.isNotEmpty) ...[
          ...message.attachments.map(_attachmentPreview),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent.secondary, accent.primary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AiFormattedText(
                text: message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ],
    );

    if (accent.bubbleStyle == BubbleStyle.glass) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: radius,
              border: Border.all(color: accent.secondary.withValues(alpha: 0.3)),
            ),
            child: inner,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E35) : Colors.white,
        borderRadius: radius,
        border: Border.all(color: accent.secondary.withValues(alpha: 0.25)),
        boxShadow: accent.bubbleStyle == BubbleStyle.solid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: inner,
    );
  }

  BorderRadius _bubbleRadius(BubbleStyle style, {required bool isUser}) {
    const r = 20.0;
    const tail = 4.0;
    final soft = style == BubbleStyle.rounded ? 28.0 : r;
    if (isUser) {
      return BorderRadius.only(
        topLeft: Radius.circular(soft),
        topRight: Radius.circular(soft),
        bottomLeft: Radius.circular(soft),
        bottomRight: Radius.circular(tail),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(tail),
      topRight: Radius.circular(soft),
      bottomLeft: Radius.circular(soft),
      bottomRight: Radius.circular(soft),
    );
  }

  Widget _attachmentPreview(MessageAttachment a) {
    if (a.type == AttachmentType.image &&
        a.localPath != null &&
        !kIsWeb &&
        File(a.localPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(a.localPath!),
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Row(
      children: [
        Icon(
          a.type == AttachmentType.image ? Icons.image_rounded : Icons.attach_file,
          size: 16,
          color: Colors.white70,
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(a.name, style: const TextStyle(fontSize: 12, color: Colors.white70))),
      ],
    );
  }
}

class _AiTypingBubble extends StatelessWidget {
  const _AiTypingBubble({required this.index, required this.accent});

  final int index;
  final AppAccentTheme accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 48, top: 6, bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E35) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: accent.secondary),
            const SizedBox(width: 10),
            const TypingIndicator(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
  }
}

void _copyMessage(BuildContext context, String text) {
  if (text.trim().isEmpty) return;
  Clipboard.setData(ClipboardData(text: text));
  final s = context.read<LocaleProvider>().strings;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(s.copied),
        ],
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onCopy, required this.color});

  final VoidCallback onCopy;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Tooltip(
            message: 'Copy',
            child: Icon(Icons.copy_rounded, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}

class _AiFormattedText extends StatelessWidget {
  const _AiFormattedText({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i.isOdd;
      final lines = parts[i].split('\n');
      for (var j = 0; j < lines.length; j++) {
        if (lines[j].isNotEmpty) {
          spans.add(
            TextSpan(
              text: lines[j],
              style: style?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          );
        }
        if (j < lines.length - 1) spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(
      TextSpan(children: spans.isEmpty ? [TextSpan(text: text, style: style)] : spans),
    );
  }
}
