import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger_service.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';

class ChatHistoryProvider extends ChangeNotifier {
  static const String _userIdKey = 'chat_user_id';

  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = [];
  bool _isLoading = false;
  String? _userId;
  String? _currentSessionId;
  final _supabase = Supabase.instance.client;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;
  bool get hasMessages => _messages.isNotEmpty;

  Future<void> initialize() async {
    try {
      // Initialize User ID
      await _initializeUserId();

      // Load sessions
      await _loadSessions();

      // If we have sessions, load the most recent one
      if (_sessions.isNotEmpty) {
        await loadSession(_sessions.first.id);
      } else {
        // If no sessions, create a new one automatically
        await startNewChat();
      }
    } catch (e) {
      logger.error('Failed to initialize chat history: $e');
      // Fallback: just show welcome message
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    }
  }

  Future<void> _initializeUserId() async {
    // Check if we have a logged-in user (if auth is added later)
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _userId = currentUser.id;
    } else {
      // Use persistent device ID for anonymous users
      try {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString(_userIdKey);
        if (_userId == null) {
          _userId = const Uuid().v4();
          await prefs.setString(_userIdKey, _userId!);
        }
      } catch (e) {
        // Fallback if SharedPreferences fails, use a temporary session ID
        logger.error('Failed to get device ID: $e');
        _userId = const Uuid().v4();
      }
    }
  }

  Future<void> _loadSessions() async {
    if (_userId == null) return;

    try {
      // Check for legacy messages (null session_id) and migrate them
      await _ensureLegacySession();

      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      _sessions.clear();
      for (final data in response) {
        _sessions.add(ChatSession.fromSupabase(data));
      }
      notifyListeners();
    } catch (e) {
      logger.error('Failed to load sessions: $e');
    }
  }

  Future<void> _ensureLegacySession() async {
    try {
      // Check if we have messages with null session_id
      final response = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('user_id', _userId!)
          .filter('session_id', 'is', null)
          .limit(1);

      if (response.isNotEmpty) {
        logger.info('Found legacy messages, creating migration session...');
        // Create a legacy session
        final session = await _createSession('Previous Chat');

        // Update all null session_id messages to this session
        await _supabase
            .from('chat_messages')
            .update({'session_id': session.id})
            .eq('user_id', _userId!)
            .filter('session_id', 'is', null);

        logger.info('Migrated legacy messages to session ${session.id}');
      }
    } catch (e) {
      logger.error('Failed to migrate legacy session: $e');
    }
  }

  Future<ChatSession> _createSession(String title) async {
    final response = await _supabase
        .from('chat_sessions')
        .insert({
          'user_id': _userId,
          'title': title,
        })
        .select()
        .single();

    return ChatSession.fromSupabase(response);
  }

  Future<void> startNewChat() async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final session = await _createSession('New Chat');
      _sessions.insert(0, session);
      _currentSessionId = session.id;

      _messages.clear();
      _addWelcomeMessage();
    } catch (e) {
      logger.error('Failed to start new chat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSession(String sessionId) async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      _currentSessionId = sessionId;
      notifyListeners();

      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', _userId!)
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      _messages.clear();
      for (final data in response) {
        _messages.add(ChatMessage.fromSupabase(data));
      }

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    } catch (e) {
      logger.error('Failed to load session messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase.from('chat_sessions').delete().eq('id', sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);

      if (_currentSessionId == sessionId) {
        if (_sessions.isNotEmpty) {
          await loadSession(_sessions.first.id);
        } else {
          await startNewChat();
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      logger.error('Failed to delete session: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      sessionId: _currentSessionId,
      text:
          "Assalamu Alaikum! I'm your Islamic knowledge assistant. I can help you with questions about:\n\n"
          "• The Holy Quran and Tafsir\n"
          "• Hadith and Sunnah\n"
          "• Islamic jurisprudence (Fiqh)\n"
          "• Prayer and worship\n"
          "• Islamic history\n\n"
          "How may I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(welcomeMessage);
    notifyListeners();
    // We don't save the welcome message to DB to avoid clutter
  }

  // Removed _loadMessages as it is replaced by loadSession and _loadSessions

  Future<void> _saveMessage(ChatMessage message) async {
    if (_userId == null) return;

    // 1. Save to Supabase
    try {
      await _supabase
          .from('chat_messages')
          .insert(message.toSupabase(_userId!));

      // Update session title if it's the first user message
      if (message.isUser && _messages.where((m) => m.isUser).length == 1) {
        _updateSessionTitle(message.text);
      }
    } catch (e) {
      logger.error('Failed to save message to Supabase: $e');
    }

    // 2. Save to Hive (Backup) - Simplified for now, maybe just save current session?
    // For now, we skip Hive backup for multi-session to avoid complexity,
    // or we could save just the current session messages.
  }

  Future<void> _updateSessionTitle(String firstMessage) async {
    if (_currentSessionId == null) return;

    // Generate a short title from the first message (max 30 chars)
    String title = firstMessage.split('\n').first;
    if (title.length > 30) {
      title = '${title.substring(0, 27)}...';
    }

    try {
      await _supabase
          .from('chat_sessions')
          .update({'title': title}).eq('id', _currentSessionId!);

      // Update local list
      final index = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (index != -1) {
        _sessions[index] = ChatSession(
          id: _sessions[index].id,
          userId: _sessions[index].userId,
          title: title,
          createdAt: _sessions[index].createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      logger.warning('Failed to update session title: $e');
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
    _saveMessage(message);
  }

  void addUserMessage(String text) {
    final message = ChatMessage(
      sessionId: _currentSessionId,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    addMessage(message);
  }

  void addAssistantMessage(String text,
      {bool isError = false, bool shouldShowIftaLink = false}) {
    final message = ChatMessage(
      sessionId: _currentSessionId,
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: isError,
      shouldShowIftaLink: shouldShowIftaLink,
    );
    addMessage(message);
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    // In multi-session context, this might mean "Delete Current Chat"
    if (_currentSessionId != null) {
      await deleteSession(_currentSessionId!);
    }
  }

  Future<void> exportChatHistory() async {
    // This could be used for sharing chat history
    // Return formatted string of all messages
  }

  // Get messages count for statistics
  int get totalMessages => _messages.length;
  int get userMessagesCount => _messages.where((msg) => msg.isUser).length;
  int get assistantMessagesCount =>
      _messages.where((msg) => !msg.isUser).length;
}
