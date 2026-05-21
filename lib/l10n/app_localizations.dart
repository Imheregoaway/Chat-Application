import 'package:flutter/material.dart';

/// Lightweight UI translations (en, es, fr, de, hi).
class AppLocalizations {
  AppLocalizations(this.languageCode);

  final String languageCode;

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('hi'),
  ];

  static AppLocalizations of(Locale locale) {
    return AppLocalizations(locale.languageCode);
  }

  static const _strings = <String, Map<String, String>>{
    'appTitle': {
      'en': 'AI Assistant',
      'es': 'Asistente IA',
      'fr': 'Assistant IA',
      'de': 'KI-Assistent',
      'hi': 'AI सहायक',
    },
    'howCanIHelp': {
      'en': 'How can I help you?',
      'es': '¿En qué puedo ayudarte?',
      'fr': 'Comment puis-je vous aider ?',
      'de': 'Wie kann ich helfen?',
      'hi': 'मैं आपकी कैसे मदद कर सकता हूँ?',
    },
    'askAnything': {
      'en': 'Ask anything...',
      'es': 'Pregunta lo que quieras...',
      'fr': 'Posez votre question...',
      'de': 'Fragen Sie etwas...',
      'hi': 'कुछ भी पूछें...',
    },
    'tryAsking': {
      'en': 'Try asking',
      'es': 'Prueba preguntar',
      'fr': 'Essayez de demander',
      'de': 'Probieren Sie',
      'hi': 'पूछकर देखें',
    },
    'backendOffline': {
      'en': 'Backend offline',
      'es': 'Servidor desconectado',
      'fr': 'Serveur hors ligne',
      'de': 'Backend offline',
      'hi': 'बैकएंड ऑफ़लाइन',
    },
    'backendOnline': {
      'en': 'LangGraph + ChromaDB + HF',
      'es': 'LangGraph + ChromaDB + HF',
      'fr': 'LangGraph + ChromaDB + HF',
      'de': 'LangGraph + ChromaDB + HF',
      'hi': 'LangGraph + ChromaDB + HF',
    },
    'settings': {
      'en': 'Settings',
      'es': 'Ajustes',
      'fr': 'Paramètres',
      'de': 'Einstellungen',
      'hi': 'सेटिंग्स',
    },
    'history': {
      'en': 'Chat history',
      'es': 'Historial',
      'fr': 'Historique',
      'de': 'Verlauf',
      'hi': 'चैट इतिहास',
    },
    'newChat': {
      'en': 'New chat',
      'es': 'Nuevo chat',
      'fr': 'Nouveau chat',
      'de': 'Neuer Chat',
      'hi': 'नई चैट',
    },
    'clearChat': {
      'en': 'Clear chat',
      'es': 'Borrar chat',
      'fr': 'Effacer le chat',
      'de': 'Chat leeren',
      'hi': 'चैट साफ़ करें',
    },
    'clearChatConfirm': {
      'en': 'This will remove all messages in this conversation.',
      'es': 'Se eliminarán todos los mensajes.',
      'fr': 'Tous les messages seront supprimés.',
      'de': 'Alle Nachrichten werden gelöscht.',
      'hi': 'इस बातचीत के सभी संदेश हट जाएंगे।',
    },
    'cancel': {
      'en': 'Cancel',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'de': 'Abbrechen',
      'hi': 'रद्द',
    },
    'clear': {
      'en': 'Clear',
      'es': 'Borrar',
      'fr': 'Effacer',
      'de': 'Leeren',
      'hi': 'साफ़',
    },
    'exportShare': {
      'en': 'Export & share',
      'es': 'Exportar y compartir',
      'fr': 'Exporter et partager',
      'de': 'Exportieren',
      'hi': 'निर्यात और साझा',
    },
    'copyAll': {
      'en': 'Copy all',
      'es': 'Copiar todo',
      'fr': 'Tout copier',
      'de': 'Alles kopieren',
      'hi': 'सब कॉपी',
    },
    'shareMarkdown': {
      'en': 'Share as Markdown',
      'es': 'Compartir Markdown',
      'fr': 'Partager Markdown',
      'de': 'Als Markdown teilen',
      'hi': 'Markdown साझा',
    },
    'voiceListening': {
      'en': 'Listening...',
      'es': 'Escuchando...',
      'fr': 'Écoute...',
      'de': 'Hört zu...',
      'hi': 'सुन रहा है...',
    },
    'attachFile': {
      'en': 'Attach file',
      'es': 'Adjuntar archivo',
      'fr': 'Joindre un fichier',
      'de': 'Datei anhängen',
      'hi': 'फ़ाइल जोड़ें',
    },
    'attachImage': {
      'en': 'Attach image',
      'es': 'Adjuntar imagen',
      'fr': 'Joindre une image',
      'de': 'Bild anhängen',
      'hi': 'छवि जोड़ें',
    },
    'wallpaper': {
      'en': 'Chat wallpaper',
      'es': 'Fondo de chat',
      'fr': 'Fond d\'écran',
      'de': 'Chat-Hintergrund',
      'hi': 'चैट वॉलपेपर',
    },
    'appearance': {
      'en': 'Appearance',
      'es': 'Apariencia',
      'fr': 'Apparence',
      'de': 'Darstellung',
      'hi': 'दिखावट',
    },
    'accentColor': {
      'en': 'Accent color',
      'es': 'Color de acento',
      'fr': 'Couleur d\'accent',
      'de': 'Akzentfarbe',
      'hi': 'एक्सेंट रंग',
    },
    'bubbleStyle': {
      'en': 'Bubble style',
      'es': 'Estilo de burbuja',
      'fr': 'Style des bulles',
      'de': 'Blasenstil',
      'hi': 'बबल स्टाइल',
    },
    'language': {
      'en': 'Language',
      'es': 'Idioma',
      'fr': 'Langue',
      'de': 'Sprache',
      'hi': 'भाषा',
    },
    'noHistory': {
      'en': 'No saved chats yet',
      'es': 'Sin chats guardados',
      'fr': 'Aucun chat enregistré',
      'de': 'Keine gespeicherten Chats',
      'hi': 'कोई सहेजी चैट नहीं',
    },
    'deleteSession': {
      'en': 'Delete chat?',
      'es': '¿Eliminar chat?',
      'fr': 'Supprimer le chat ?',
      'de': 'Chat löschen?',
      'hi': 'चैट हटाएँ?',
    },
    'poweredBy': {
      'en': 'Powered by LangGraph, ChromaDB RAG, and Hugging Face.',
      'es': 'LangGraph, ChromaDB y Hugging Face.',
      'fr': 'LangGraph, ChromaDB et Hugging Face.',
      'de': 'LangGraph, ChromaDB und Hugging Face.',
      'hi': 'LangGraph, ChromaDB और Hugging Face।',
    },
    'sourcesUsed': {
      'en': 'Used {n} ChromaDB source(s)',
      'es': '{n} fuente(s) ChromaDB',
      'fr': '{n} source(s) ChromaDB',
      'de': '{n} ChromaDB-Quelle(n)',
      'hi': '{n} ChromaDB स्रोत',
    },
    'copied': {
      'en': 'Copied to clipboard',
      'es': 'Copiado',
      'fr': 'Copié',
      'de': 'Kopiert',
      'hi': 'कॉपी हो गया',
    },
    'exported': {
      'en': 'Chat exported',
      'es': 'Chat exportado',
      'fr': 'Chat exporté',
      'de': 'Chat exportiert',
      'hi': 'चैट निर्यात',
    },
    'pendingAttachments': {
      'en': 'Attachments ready to send',
      'es': 'Adjuntos listos',
      'fr': 'Pièces jointes prêtes',
      'de': 'Anhänge bereit',
      'hi': 'अटैचमेंट तैयार',
    },
  };

  String t(String key, {Map<String, String>? params}) {
    final map = _strings[key];
    var value = map?[languageCode] ?? map?['en'] ?? key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }

  String get appTitle => t('appTitle');
  String get howCanIHelp => t('howCanIHelp');
  String get askAnything => t('askAnything');
  String get tryAsking => t('tryAsking');
  String get backendOffline => t('backendOffline');
  String get backendOnline => t('backendOnline');
  String get settings => t('settings');
  String get history => t('history');
  String get newChat => t('newChat');
  String get clearChat => t('clearChat');
  String get clearChatConfirm => t('clearChatConfirm');
  String get cancel => t('cancel');
  String get clear => t('clear');
  String get exportShare => t('exportShare');
  String get copyAll => t('copyAll');
  String get shareMarkdown => t('shareMarkdown');
  String get voiceListening => t('voiceListening');
  String get attachFile => t('attachFile');
  String get attachImage => t('attachImage');
  String get wallpaper => t('wallpaper');
  String get appearance => t('appearance');
  String get accentColor => t('accentColor');
  String get bubbleStyle => t('bubbleStyle');
  String get language => t('language');
  String get noHistory => t('noHistory');
  String get deleteSession => t('deleteSession');
  String get poweredBy => t('poweredBy');
  String get pendingAttachments => t('pendingAttachments');
  String get copied => t('copied');
  String get exported => t('exported');

  String sourcesUsed(int n) => t('sourcesUsed', params: {'n': '$n'});
}
