import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_message.dart';
import '../models/chat_session.dart';
import '../models/message_attachment.dart';
import '../services/ai_backend_service.dart';
import '../services/api_config_service.dart';
import '../services/attachment_service.dart';
import '../services/chat_history_service.dart';

class AiChatProvider extends ChangeNotifier {
  AiChatProvider({
    AiBackendService? backend,
    ApiConfigService? config,
    ChatHistoryService? history,
    AttachmentService? attachments,
  })  : _backend = backend ?? AiBackendService(),
        _config = config ?? ApiConfigService(),
        _history = history ?? ChatHistoryService(),
        _attachments = attachments ?? AttachmentService();

  final AiBackendService _backend;
  final ApiConfigService _config;
  final ChatHistoryService _history;
  final AttachmentService _attachments;
  final _uuid = const Uuid();

  final List<AiMessage> _messages = [];
  final List<MessageAttachment> _pendingAttachments = [];
  bool _isGenerating = false;
  String? _error;
  bool _backendOnline = false;
  String? _lastContext;
  int _lastSources = 0;
  Map<String, dynamic>? _health;
  String? _sessionId;
  String _sessionTitle = 'New chat';
  String _localeCode = 'en';

  List<AiMessage> get messages => List.unmodifiable(_messages);
  List<MessageAttachment> get pendingAttachments =>
      List.unmodifiable(_pendingAttachments);
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get isEmpty => _messages.isEmpty;
  bool get backendOnline => _backendOnline;
  String? get lastContext => _lastContext;
  int get lastSources => _lastSources;
  Map<String, dynamic>? get health => _health;
  String? get sessionId => _sessionId;
  String get sessionTitle => _sessionTitle;

  static const suggestedPrompts = [
    'What is LangGraph used for?',
    'How does ChromaDB work in this app?',
    'Explain RAG in simple terms',
    'Help me brainstorm app ideas',
  ];

  void setLocaleCode(String code) {
    _localeCode = code;
  }

  Future<void> init() async {
    await checkBackend();
    await startNewSession(saveCurrent: false);
  }

  Future<void> checkBackend() async {
    try {
      final baseUrl = await _config.getBaseUrl();
      _health = await _backend.healthCheck(baseUrl);
      _backendOnline = _health?['status'] == 'ok';
      _error = null;
    } catch (e) {
      _backendOnline = false;
      _health = null;
      _error = 'Backend offline. Start: cd backend && python run.py';
    }
    notifyListeners();
  }

  Future<void> startNewSession({bool saveCurrent = true}) async {
    if (saveCurrent && _messages.isNotEmpty && _sessionId != null) {
      await _persistSession();
    }
    _sessionId = _uuid.v4();
    _sessionTitle = 'New chat';
    _messages.clear();
    _pendingAttachments.clear();
    _error = null;
    _lastContext = null;
    _lastSources = 0;
    notifyListeners();
  }

  Future<void> loadSession(ChatSession session) async {
    if (_messages.isNotEmpty && _sessionId != null) {
      await _persistSession();
    }
    _sessionId = session.id;
    _sessionTitle = session.title;
    _messages
      ..clear()
      ..addAll(session.messages.where((m) => !m.isStreaming));
    _pendingAttachments.clear();
    _error = null;
    notifyListeners();
  }

  Future<List<ChatSession>> loadAllSessions() => _history.loadAll();

  Future<void> deleteSession(String id) async {
    await _history.delete(id);
    if (_sessionId == id) {
      await startNewSession(saveCurrent: false);
    }
  }

  void addPendingAttachment(MessageAttachment attachment) {
    _pendingAttachments.add(attachment);
    notifyListeners();
  }

  void removePendingAttachment(String id) {
    _pendingAttachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void clearPendingAttachments() {
    _pendingAttachments.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && _pendingAttachments.isEmpty) return;
    if (_isGenerating) return;

    final attachmentBlocks =
        _attachments.buildAttachmentContext(_pendingAttachments);
    final sentAttachments = List<MessageAttachment>.from(_pendingAttachments);
    _pendingAttachments.clear();

    var messageForApi = trimmed;
    if (attachmentBlocks.isNotEmpty) {
      final block = attachmentBlocks.join('\n\n');
      messageForApi = trimmed.isEmpty
          ? block
          : '$trimmed\n\n---\nAttachments:\n$block';
    }
    if (messageForApi.trim().isEmpty) return;

    _error = null;
    _messages.add(
      AiMessage(
        id: _uuid.v4(),
        content: trimmed.isEmpty ? '(attachments)' : trimmed,
        role: AiMessageRole.user,
        timestamp: DateTime.now(),
        attachments: sentAttachments,
      ),
    );
    _updateSessionTitle(trimmed);

    final placeholderId = _uuid.v4();
    _messages.add(
      AiMessage(
        id: placeholderId,
        content: '',
        role: AiMessageRole.assistant,
        timestamp: DateTime.now(),
        isStreaming: true,
      ),
    );
    _isGenerating = true;
    notifyListeners();

    try {
      final baseUrl = await _config.getBaseUrl();
      final history = _messages
          .where((m) => m.id != placeholderId && !m.isStreaming)
          .toList();

      final result = await _backend.chat(
        baseUrl: baseUrl,
        message: messageForApi,
        history: history,
        locale: _localeCode,
        attachmentContext: attachmentBlocks,
      );

      _lastContext = result.context;
      _lastSources = result.sources;

      final idx = _messages.indexWhere((m) => m.id == placeholderId);
      if (idx >= 0) {
        _messages[idx] = AiMessage(
          id: placeholderId,
          content: result.response,
          role: AiMessageRole.assistant,
          timestamp: DateTime.now(),
        );
      }
      await _persistSession();
    } on AiBackendException catch (e) {
      _messages.removeWhere((m) => m.id == placeholderId);
      _error = e.message;
    } catch (_) {
      _messages.removeWhere((m) => m.id == placeholderId);
      _error = 'Cannot reach backend. Run the Python server on port 8000.';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _updateSessionTitle(String text) {
    if (_messages.where((m) => m.isUser).length > 1) return;
    final title = text.trim();
    if (title.isNotEmpty) {
      _sessionTitle = title.length > 48 ? '${title.substring(0, 48)}…' : title;
    }
  }

  Future<void> _persistSession() async {
    if (_sessionId == null || _messages.isEmpty) return;
    final session = ChatSession(
      id: _sessionId!,
      title: _sessionTitle,
      updatedAt: DateTime.now(),
      messages: _messages.where((m) => !m.isStreaming).toList(),
    );
    await _history.upsert(session);
  }

  Future<void> addKnowledge(String text) async {
    final baseUrl = await _config.getBaseUrl();
    await _backend.addKnowledge(baseUrl: baseUrl, text: text);
  }

  Future<void> clearChat() async {
    if (_isGenerating) return;
    _messages.clear();
    _pendingAttachments.clear();
    _error = null;
    _lastContext = null;
    _lastSources = 0;
    if (_sessionId != null) {
      await _history.delete(_sessionId!);
    }
    await startNewSession(saveCurrent: false);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
