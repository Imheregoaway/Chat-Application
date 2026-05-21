import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/accent_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallpaper_provider.dart';
import 'models/chat_wallpaper.dart';
import 'screens/ai_chat_screen.dart';
import 'widgets/chat_wallpaper_background.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => AccentProvider()..load()),
        ChangeNotifierProvider(create: (_) => WallpaperProvider()..load()),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
      ],
      child: Consumer4<ThemeProvider, LocaleProvider, AccentProvider, WallpaperProvider>(
        builder: (context, theme, locale, accent, wallpaper, _) {
          final ready = locale.loaded && accent.loaded && wallpaper.loaded;
          final accentTheme = accent.accentTheme;

          return MaterialApp(
            title: 'AI Chat',
            debugShowCheckedModeBanner: false,
            locale: locale.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(accentTheme),
            darkTheme: AppTheme.dark(accentTheme),
            themeMode: theme.themeMode,
            home: ready
                ? _AppHome(
                    wallpaper: wallpaper.wallpaper,
                    localeCode: locale.locale.languageCode,
                  )
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
          );
        },
      ),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome({required this.wallpaper, required this.localeCode});

  final ChatWallpaper wallpaper;
  final String localeCode;

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiChatProvider>().setLocaleCode(widget.localeCode);
    });
  }

  @override
  void didUpdateWidget(_AppHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeCode != widget.localeCode) {
      context.read<AiChatProvider>().setLocaleCode(widget.localeCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatWallpaperBackground(
      wallpaper: widget.wallpaper,
      child: const AiChatScreen(),
    );
  }
}
