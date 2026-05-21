import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_session.dart';

class ChatHistoryService {
  static const _key = 'chat_sessions_v1';
  static const _maxSessions = 50;

  Future<List<ChatSession>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final sessions = list
        .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  Future<void> saveAll(List<ChatSession> sessions) async {
    final trimmed = sessions.take(_maxSessions).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> upsert(ChatSession session) async {
    final all = await loadAll();
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.insert(0, session);
    }
    await saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((s) => s.id == id);
    await saveAll(all);
  }
}
