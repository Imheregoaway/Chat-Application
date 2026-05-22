import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_accent_theme.dart';
import '../core/theme/app_colors.dart';
import '../models/accent_preset.dart';
import '../models/bubble_style.dart';
import '../models/chat_wallpaper.dart';
import '../providers/accent_provider.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../services/api_config_service.dart';
import '../widgets/chat_wallpaper_background.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _knowledgeController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = await ApiConfigService().getBaseUrl();
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _knowledgeController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    setState(() => _saving = true);
    await ApiConfigService().saveBaseUrl(_urlController.text);
    if (!mounted) return;
    await context.read<AiChatProvider>().checkBackend();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backend URL saved')),
    );
  }

  Future<void> _addKnowledge() async {
    final text = _knowledgeController.text.trim();
    if (text.isEmpty) return;
    try {
      final ai = context.read<AiChatProvider>();
      await ai.addKnowledge(text);
      _knowledgeController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to ChromaDB knowledge base')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _reindexKnowledge() async {
    try {
      final ai = context.read<AiChatProvider>();
      final count = await ai.reindexKnowledge();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rebuilt search index ($count documents)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final wallpaperProvider = context.watch<WallpaperProvider>();
    final accentProvider = context.watch<AccentProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final ai = context.watch<AiChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final health = ai.health;
    final s = localeProvider.strings;
    final accent =
        Theme.of(context).extension<AppAccentTheme>() ?? AppAccentTheme.defaultTheme();
    final wallpaper = wallpaperProvider.wallpaper;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(s.settings),
        backgroundColor: Colors.transparent,
      ),
      body: ChatWallpaperBackground(
        wallpaper: wallpaper,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend (LangGraph + ChromaDB)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'API Base URL',
                            hintText: 'http://127.0.0.1:8000',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving ? null : _saveUrl,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save & Test Connection'),
                        ),
                        if (health != null) ...[
                          const SizedBox(height: 16),
                          _InfoRow('Status', health['status']?.toString() ?? '-'),
                          _InfoRow(
                            'Hugging Face',
                            health['huggingface_configured'] == true ? 'Yes' : 'No (demo mode)',
                          ),
                          _InfoRow(
                            'ChromaDB docs',
                            '${health['chroma_documents'] ?? 0}',
                          ),
                          _InfoRow('Chat model', health['chat_model']?.toString() ?? '-'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Add Knowledge (ChromaDB)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _knowledgeController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Text to index',
                            hintText: 'Paste facts, notes, or docs for RAG...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: ai.backendOnline ? _addKnowledge : null,
                            icon: const Icon(Icons.storage_rounded),
                            label: const Text('Index in ChromaDB'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: ai.backendOnline ? _reindexKnowledge : null,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Rebuild search index'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.language,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Locale>(
                        isExpanded: true,
                        value: localeProvider.locale,
                        items: const [
                          DropdownMenuItem(value: Locale('en'), child: Text('English')),
                          DropdownMenuItem(value: Locale('es'), child: Text('Español')),
                          DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                          DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
                          DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                        ],
                        onChanged: (loc) async {
                          if (loc == null) return;
                          await localeProvider.setLocale(loc);
                          if (!context.mounted) return;
                          context.read<AiChatProvider>().setLocaleCode(loc.languageCode);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.accentColor,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AccentPreset.values.map((preset) {
                      final selected = accentProvider.preset == preset;
                      return GestureDetector(
                        onTap: () => accentProvider.setPreset(preset),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [preset.primary, preset.secondary],
                            ),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: preset.primary.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.bubbleStyle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: BubbleStyle.values.map((style) {
                        return Column(
                          children: [
                            ListTile(
                              title: Text(style.label),
                              subtitle: Text(
                                style.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: accentProvider.bubbleStyle == style
                                  ? Icon(Icons.check_circle_rounded, color: accent.primary)
                                  : null,
                              onTap: () => accentProvider.setBubbleStyle(style),
                            ),
                            if (style != BubbleStyle.values.last)
                              Divider(
                                height: 1,
                                color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE8E9F3),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.wallpaper,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a background style for your chat screen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: ChatWallpaper.values.length,
                    itemBuilder: (context, index) {
                      final wp = ChatWallpaper.values[index];
                      return WallpaperPreview(
                        wallpaper: wp,
                        selected: wallpaperProvider.wallpaper == wp,
                        onTap: () => wallpaperProvider.setWallpaper(wp),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.appearance,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.offline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: [
                        _ThemeTile(
                          icon: Icons.light_mode_rounded,
                          label: 'Light',
                          selected: themeProvider.themeMode == ThemeMode.light,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE8E9F3),
                        ),
                        _ThemeTile(
                          icon: Icons.dark_mode_rounded,
                          label: 'Dark',
                          selected: themeProvider.themeMode == ThemeMode.dark,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE8E9F3),
                        ),
                        _ThemeTile(
                          icon: Icons.brightness_auto_rounded,
                          label: 'System',
                          selected: themeProvider.themeMode == ThemeMode.system,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Stack: LangGraph → ChromaDB retrieve → Hugging Face generate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.offline,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).extension<AppAccentTheme>()?.primary ?? AppColors.primary,
      ),
      title: Text(label),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).extension<AppAccentTheme>()?.primary ?? AppColors.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
