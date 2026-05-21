import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_accent_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_session.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/chat_wallpaper_background.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/glass_container.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<AiChatProvider>().loadAllSessions();
    if (mounted) {
      setState(() {
        _sessions = list;
        _loading = false;
      });
    }
  }

  AppLocalizations get _s => context.read<LocaleProvider>().strings;

  AppAccentTheme get _accent =>
      Theme.of(context).extension<AppAccentTheme>() ?? AppAccentTheme.defaultTheme();

  Future<void> _openSession(ChatSession session) async {
    await context.read<AiChatProvider>().loadSession(session);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteSession(ChatSession session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.deleteSession),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.clear, style: TextStyle(color: _accent.primary)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AiChatProvider>().deleteSession(session.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = context.watch<WallpaperProvider>().wallpaper;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_s.history),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.read<AiChatProvider>().startNewSession();
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(_s.newChat),
          ),
        ],
      ),
      body: ChatWallpaperBackground(
        wallpaper: wallpaper,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _s.noHistory,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final s = _sessions[index];
                      final preview = s.messages
                          .where((m) => m.content.isNotEmpty && !m.isStreaming)
                          .map((m) => m.content)
                          .lastOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassContainer(
                          child: ListTile(
                            onTap: () => _openSession(s),
                            title: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              preview ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => _deleteSession(s),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _accent.primary.withValues(alpha: 0.2),
                              child: Icon(Icons.chat_bubble_outline, color: _accent.primary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
