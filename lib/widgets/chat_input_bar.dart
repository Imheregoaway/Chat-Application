import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_accent_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/locale_provider.dart';
import '../services/attachment_service.dart';
import '../services/voice_input_service.dart';
import 'glass_container.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isGenerating,
    required this.strings,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;
  final AppLocalizations strings;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _voice = VoiceInputService();
  final _attachmentService = AttachmentService();
  bool _voiceReady = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    final ok = await _voice.initialize();
    if (mounted) setState(() => _voiceReady = ok);
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  AppAccentTheme get _accent =>
      Theme.of(context).extension<AppAccentTheme>() ?? AppAccentTheme.defaultTheme();

  Future<void> _toggleVoice() async {
    if (!_voiceReady || widget.isGenerating) return;
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final localeProvider = context.read<LocaleProvider>();
    setState(() => _listening = true);
    await _voice.startListening(
      localeId: localeProvider.speechLocaleId,
      onResult: (text) {
        widget.controller.text = text;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        if (!_voice.isListening && mounted) {
          setState(() => _listening = false);
        }
      },
    );
  }

  Future<void> _pickFile() async {
    final ai = context.read<AiChatProvider>();
    final att = await _attachmentService.pickTextFile();
    if (att != null) ai.addPendingAttachment(att);
  }

  Future<void> _pickImage() async {
    final ai = context.read<AiChatProvider>();
    final att = await _attachmentService.pickImage();
    if (att != null) ai.addPendingAttachment(att);
  }

  void _showAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(widget.strings.attachFile),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(widget.strings.attachImage),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiChatProvider>();
    final pending = ai.pendingAttachments;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: pending
                  .map(
                    (a) => Chip(
                      label: Text(a.name, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => ai.removePendingAttachment(a.id),
                      backgroundColor: _accent.primary.withValues(alpha: 0.15),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_listening)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.strings.voiceListening,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _accent.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            borderRadius: 28,
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.isGenerating ? null : _showAttachMenu,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: widget.strings.attachFile,
                ),
                IconButton(
                  onPressed: (_voiceReady && !widget.isGenerating) ? _toggleVoice : null,
                  icon: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _listening ? _accent.primary : null,
                  ),
                  tooltip: widget.strings.voiceListening,
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    enabled: !widget.isGenerating,
                    decoration: InputDecoration(
                      hintText: widget.strings.askAnything,
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: widget.isGenerating
                        ? null
                        : (_) => widget.onSend(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isGenerating
                          ? [
                              Colors.grey,
                              Colors.grey.withValues(alpha: 0.7),
                            ]
                          : [_accent.secondary, _accent.primary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: widget.isGenerating ? null : widget.onSend,
                    icon: Icon(
                      widget.isGenerating
                          ? Icons.hourglass_top_rounded
                          : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
