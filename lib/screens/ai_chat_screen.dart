import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_accent_theme.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/locale_provider.dart';
import '../services/export_chat_service.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_prompt_chip.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/glass_container.dart';
import 'chat_history_screen.dart';
import 'settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _export = ExportChatService();

  AppLocalizations get _s => context.read<LocaleProvider>().strings;

  AppAccentTheme get _accent =>
      Theme.of(context).extension<AppAccentTheme>() ?? AppAccentTheme.defaultTheme();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locale = context.read<LocaleProvider>().locale.languageCode;
      context.read<AiChatProvider>()
        ..setLocaleCode(locale)
        ..init();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final content = text ?? _messageController.text;
    if (content.trim().isEmpty &&
        context.read<AiChatProvider>().pendingAttachments.isEmpty) {
      return;
    }
    _messageController.clear();
    await context.read<AiChatProvider>().sendMessage(content);
    _scrollToBottom();
  }

  void _confirmClear() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.clearChat),
        content: Text(_s.clearChatConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_s.cancel)),
          TextButton(
            onPressed: () {
              context.read<AiChatProvider>().clearChat();
              Navigator.pop(ctx);
            },
            child: Text(_s.clear, style: TextStyle(color: _accent.primary)),
          ),
        ],
      ),
    );
  }

  void _showExportMenu() {
    final ai = context.read<AiChatProvider>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: Text(_s.copyAll),
              onTap: () async {
                Navigator.pop(ctx);
                await _export.copyAll(ai.messages);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_s.copied)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: Text(_s.shareMarkdown),
              onTap: () async {
                Navigator.pop(ctx);
                await _export.shareMarkdown(
                  ai.messages,
                  title: ai.sessionTitle,
                );
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
    final s = context.watch<LocaleProvider>().strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            borderRadius: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent.secondary, _accent.primary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.appTitle, style: Theme.of(context).textTheme.titleLarge),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: ai.backendOnline ? Colors.greenAccent : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              ai.backendOnline ? s.backendOnline : s.backendOffline,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  tooltip: s.history,
                ),
                if (!ai.isEmpty) ...[
                  IconButton(
                    onPressed: ai.isGenerating ? null : _showExportMenu,
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: s.exportShare,
                  ),
                  IconButton(
                    onPressed: ai.isGenerating ? null : _confirmClear,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: s.clearChat,
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: s.settings,
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: -0.04, end: 0),
        if (ai.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Material(
              color: _accent.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.error_outline, color: _accent.primary, size: 20),
                title: Text(ai.error!, style: Theme.of(context).textTheme.bodySmall),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: ai.clearError,
                ),
              ),
            ),
          ),
        Expanded(
          child: ai.isEmpty
              ? _EmptyAiState(onPromptTap: _send, strings: s)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: ai.messages.length,
                  itemBuilder: (context, index) {
                    return AiMessageBubble(
                      message: ai.messages[index],
                      index: index,
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: ChatInputBar(
            controller: _messageController,
            onSend: () => _send(),
            isGenerating: ai.isGenerating,
            strings: s,
          ),
        ),
        if (ai.lastSources > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
            child: Text(
              s.sourcesUsed(ai.lastSources),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: _accent.secondary,
                  ),
            ),
          )
        else if (!ai.backendOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
            child: Text(
              'Start backend: cd backend && python run.py',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.offline : const Color(0xFF9E9EB8),
                  ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    ),
    );
  }
}

class _EmptyAiState extends StatelessWidget {
  const _EmptyAiState({required this.onPromptTap, required this.strings});

  final void Function(String) onPromptTap;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final accent =
        Theme.of(context).extension<AppAccentTheme>() ?? AppAccentTheme.defaultTheme();
    final prompts = AiChatProvider.suggestedPrompts;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.primary, accent.secondary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.howCanIHelp,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.poweredBy,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF9E9EB8),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.96, 0.96)),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.tryAsking,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF9E9EB8),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: prompts
                .map((p) => AiPromptChip(label: p, onTap: () => onPromptTap(p)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
