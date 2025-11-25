import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../services/islamic_ai_service.dart';
import '../../data/models/chat_message.dart';
import '../providers/enhanced_theme_provider.dart';
import '../providers/chat_history_provider.dart';

class IslamicAIAssistantScreen extends StatefulWidget {
  const IslamicAIAssistantScreen({super.key});

  @override
  State<IslamicAIAssistantScreen> createState() =>
      _IslamicAIAssistantScreenState();
}

class _IslamicAIAssistantScreenState extends State<IslamicAIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IslamicAIService? _aiService;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    // Initialize chat history provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider =
          Provider.of<ChatHistoryProvider>(context, listen: false);
      await chatProvider.initialize();
    });

    // Initialize AI service
    try {
      _aiService = IslamicAIService();
    } catch (e) {
      // Handle error if API key is not found
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiKeyErrorDialog();
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Only show button if there is scrollable content AND we are not at the bottom
      final isScrollable =
          maxScroll > 20; // Small threshold to avoid floating point errors
      final isNotAtBottom = currentScroll < maxScroll - 100;

      final shouldShow = isScrollable && isNotAtBottom;

      if (shouldShow != _showScrollButton) {
        setState(() {
          _showScrollButton = shouldShow;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _aiService == null) return;

    final userMessage = _messageController.text.trim();
    final chatProvider =
        Provider.of<ChatHistoryProvider>(context, listen: false);

    // Add user message
    chatProvider.addUserMessage(userMessage);
    _messageController.clear();
    _scrollToBottom();

    // Set loading state
    chatProvider.setLoading(true);

    try {
      // Pass current history to the AI service for context
      final response = await _aiService!.askQuestion(
        userMessage,
        history: chatProvider.messages,
      );

      // Add assistant response
      chatProvider.addAssistantMessage(
        response.message,
        isError: false,
        shouldShowIftaLink: response.shouldRedirectToIfta,
      );

      chatProvider.setLoading(false);
      _scrollToBottom();

      if (response.shouldRedirectToIfta) {
        _showIftaRedirectDialog();
      }
    } catch (e) {
      chatProvider.addAssistantMessage(
        "I apologize, but I'm having trouble connecting to the service. Please try again later.",
        isError: true,
      );
      chatProvider.setLoading(false);
      _scrollToBottom();
    }
  }

  void _showIftaRedirectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consult Scholars'),
        content: const Text(
          'For more detailed guidance on this topic, would you like to visit the Egyptian Dar Al-Ifta website?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              IslamicAIService.openEgyptianIfta();
            },
            child: const Text('Visit Website'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Error'),
        content: const Text(
          'OpenAI API key not found. Please ensure you have:\n\n'
          '1. Created a .env file in the project root\n'
          '2. Added your OpenAI API key: OPENAI_API_KEY=your_key\n'
          '3. Restarted the app',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    final suggestions = [
      'Explain Surah Al-Fatiha',
      'How to pray Istikhara?',
      'Story of Prophet Yusuf',
      'Virtues of Ramadan',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mosque_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Assalamu Alaikum',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'I am your Islamic AI Assistant.\nHow can I help you today?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () {
                    _messageController.text = suggestion;
                    _sendMessage();
                  },
                  avatar: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  backgroundColor: colorScheme.surface,
                  elevation: 1,
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showHistorySheet(BuildContext context, ChatHistoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chat History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provider.sessions.length,
                  itemBuilder: (context, index) {
                    final session = provider.sessions[index];
                    final isSelected = session.id == provider.currentSessionId;
                    return ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        session.title ?? 'New Chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(session.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Chat'),
                              content: const Text(
                                  'Are you sure you want to delete this chat?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    provider.deleteSession(session.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        provider.loadSession(session.id);
                        Navigator.pop(context);
                      },
                      selected: isSelected,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context,
      ChatHistoryProvider chatProvider, ColorScheme colorScheme) {
    final currentSession = chatProvider.sessions.isEmpty
        ? null
        : chatProvider.sessions.firstWhere(
            (s) => s.id == chatProvider.currentSessionId,
            orElse: () => chatProvider.sessions.first);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showHistorySheet(context, chatProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSession?.title ?? 'New Chat',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tap to view history',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: () => chatProvider.startNewChat(),
            elevation: 0,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            tooltip: 'New Chat',
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<EnhancedThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkTheme(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ChatHistoryProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: Column(
            children: [
              _buildSessionHeader(context, chatProvider, colorScheme),
              Expanded(
                child: Stack(
                  children: [
                    chatProvider.messages.isEmpty && !chatProvider.isLoading
                        ? _buildEmptyState(context, colorScheme)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: chatProvider.messages.length +
                                (chatProvider.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == chatProvider.messages.length &&
                                  chatProvider.isLoading) {
                                return const _LoadingIndicator();
                              }

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _MessageBubble(
                                      message: chatProvider.messages[index],
                                      colorScheme: colorScheme,
                                      isDarkTheme: isDarkTheme,
                                      onRetry: () {
                                        if (index > 0) {
                                          final previousMsg =
                                              chatProvider.messages[index - 1];
                                          if (previousMsg.isUser) {
                                            _messageController.text =
                                                previousMsg.text;
                                            _sendMessage();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    if (_showScrollButton)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: _scrollToBottom,
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.arrow_downward_rounded),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _aiService != null
                            ? _sendMessage()
                            : _showApiKeyErrorDialog(),
                        decoration: InputDecoration(
                          hintText: 'Ask your question...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: chatProvider.isLoading
                          ? null
                          : (_aiService != null
                              ? _sendMessage
                              : _showApiKeyErrorDialog),
                      elevation: 0,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      child: chatProvider.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme colorScheme;
  final bool isDarkTheme;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.colorScheme,
    required this.isDarkTheme,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : message.isError
                        ? colorScheme.errorContainer
                        : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isUser)
                    Text(
                      message.text,
                      style: TextStyle(color: colorScheme.onPrimary),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: message.isError
                              ? colorScheme.onErrorContainer
                              : colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        h1: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold),
                        h2: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold),
                        h3: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold),
                        blockquote: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        code: TextStyle(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  if (message.isError && onRetry != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: onRetry,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Retry',
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (message.shouldShowIftaLink)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: () => IslamicAIService.openEgyptianIfta(),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Visit Egyptian Dar Al-Ifta'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
