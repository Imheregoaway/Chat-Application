import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_message.dart';

class AiBackendException implements Exception {
  AiBackendException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AiBackendService {
  AiBackendService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> healthCheck(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/api/health');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw AiBackendException('Backend unavailable (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<({String response, String context, int sources, bool noKnowledge})> chat({
    required String baseUrl,
    required String message,
    required List<AiMessage> history,
    String locale = 'en',
    List<String> attachmentContext = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/api/chat');
    final body = jsonEncode({
      'message': message,
      'locale': locale,
      'attachments': attachmentContext,
      'history': history
          .where((m) => !m.isStreaming && m.content.isNotEmpty)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList(),
    });

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      final detail = err is Map ? err['detail'] : null;
      throw AiBackendException(detail?.toString() ?? 'Chat failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      response: data['response'] as String? ?? '',
      context: data['context_used'] as String? ?? '',
      sources: (data['sources_count'] as num?)?.toInt() ?? 0,
      noKnowledge: data['no_knowledge'] as bool? ?? false,
    );
  }

  Future<void> addKnowledge({
    required String baseUrl,
    required String text,
    String source = 'user',
  }) async {
    final uri = Uri.parse('$baseUrl/api/knowledge');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'source': source}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiBackendException('Failed to add knowledge (${response.statusCode})');
    }
  }

  Future<void> seedKnowledge(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/api/knowledge/seed');
    final response = await _client.post(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw AiBackendException('Failed to seed knowledge');
    }
  }

  Future<int> reindexKnowledge(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/api/knowledge/reindex');
    final response = await _client.post(uri).timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      final detail = err is Map ? err['detail'] : null;
      throw AiBackendException(
        detail?.toString() ?? 'Failed to reindex knowledge (${response.statusCode})',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['reindexed'] as num?)?.toInt() ?? 0;
  }
}
