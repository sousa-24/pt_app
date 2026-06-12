import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../api_service.dart';
import '../../../app_config.dart';
import '../student_theme.dart';

class StudentFloatingChat extends StatefulWidget {
  final String token;
  final VoidCallback onClose;

  const StudentFloatingChat({
    super.key,
    required this.token,
    required this.onClose,
  });

  @override
  State<StudentFloatingChat> createState() => _StudentFloatingChatState();
}

class _StudentFloatingChatState extends State<StudentFloatingChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;
  int? _currentUserId;
  bool _isLoading = true;
  bool _isConnected = false;
  String? _errorMessage;
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _selectedContact;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final userData = await ApiService.get(
        context,
        '/api/v1/me',
        widget.token,
      );
      if (!mounted) return;

      final userId = _intValue(userData is Map ? userData['id'] : null);
      if (userData == null || userId == null) {
        setState(() {
          _errorMessage = 'Nao foi possivel identificar o aluno.';
          _isLoading = false;
        });
        return;
      }

      _currentUserId = userId;

      final contactsData = await ApiService.get(
        context,
        '/api/v1/my-contacts/',
        widget.token,
      );
      if (!mounted) return;

      if (contactsData is List) {
        _contacts = contactsData.whereType<Map<String, dynamic>>().toList();
        if (_contacts.isNotEmpty) {
          _selectedContact = _contacts.first;
        }
      }

      if (_selectedContact != null) {
        await _loadHistory();
      }

      final uri = AppConfig.websocketUri(
        userId: _currentUserId!,
        token: widget.token,
      );
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _handleSocketMessage,
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
            _errorMessage = 'Nao foi possivel conectar ao chat.';
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isConnected = false);
        },
      );

      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nao foi possivel carregar o chat agora.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final contact = _selectedContact;
    if (contact == null) return;

    final history = await ApiService.get(
      context,
      '/api/v1/messages/${contact['id']}',
      widget.token,
    );
    if (!mounted || history is! List) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(
          history.whereType<Map<String, dynamic>>().map(
            (message) => {
              'text': _text(message['content'], ''),
              'isMe': message['sender_id'] == _currentUserId,
              'sentAt': _parseDate(message['created_at']),
            },
          ),
        );
    });
    _scrollToBottom();
  }

  void _handleSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      if (data is! Map<String, dynamic>) return;

      if (data['type'] == 'message') {
        _addMessage(
          text: _text(data['content'], ''),
          isMe: data['sender_id'] == _currentUserId,
          sentAt: _parseDate(data['created_at']),
        );
      } else if (data['type'] == 'sent' && data['message'] != null) {
        final sentMessage = data['message'];
        if (sentMessage is Map<String, dynamic>) {
          _addMessage(
            text: _text(sentMessage['content'], ''),
            isMe: true,
            sentAt: _parseDate(sentMessage['created_at']),
          );
        }
      }
    } catch (_) {
      _addMessage(text: message.toString(), isMe: false);
    }
  }

  void _addMessage({
    required String text,
    required bool isMe,
    DateTime? sentAt,
  }) {
    if (!mounted || text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': isMe,
        'sentAt': sentAt ?? DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    final contact = _selectedContact;
    if (text.isEmpty ||
        contact == null ||
        _currentUserId == null ||
        _channel == null ||
        !_isConnected) {
      return;
    }

    _channel!.sink.add(
      jsonEncode({'receiver_id': contact['id'], 'content': text}),
    );
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 700;
    final width = isCompact ? media.size.width - 24 : 380.0;
    final height = isCompact ? media.size.height * 0.72 : 520.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: StudentTheme.lightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A3A3D)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _Header(contactName: _selectedContactName, onClose: widget.onClose),
            Expanded(child: _body()),
            _messageInput(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: StudentTheme.blue),
      );
    }

    if (_errorMessage != null) {
      return _EmptyState(message: _errorMessage!);
    }

    if (_contacts.isEmpty) {
      return const _EmptyState(
        message: 'Nenhum personal encontrado para conversar.',
      );
    }

    return Column(
      children: [
        if (_contacts.length > 1) _contactSelector(),
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyState(
                  message: 'Envie uma mensagem para iniciar a conversa.',
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _MessageBubble(
                      text: _text(message['text'], ''),
                      isMe: message['isMe'] == true,
                      sentAt: message['sentAt'] is DateTime
                          ? message['sentAt'] as DateTime
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _contactSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF242426),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedContact,
          dropdownColor: const Color(0xFF2C2C2E),
          iconEnabledColor: StudentTheme.darkText,
          isExpanded: true,
          items: _contacts.map((contact) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: contact,
              child: Text(
                _text(contact['name'], 'Personal'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: StudentTheme.darkText),
              ),
            );
          }).toList(),
          onChanged: (contact) {
            setState(() {
              _selectedContact = contact;
              _messages.clear();
            });
            _loadHistory();
          },
        ),
      ),
    );
  }

  Widget _messageInput() {
    final enabled = !_isLoading && _isConnected && _selectedContact != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      color: const Color(0xFF151516),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: enabled,
              style: const TextStyle(color: StudentTheme.darkText),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: enabled ? 'Escreva uma mensagem...' : 'Conectando...',
                hintStyle: const TextStyle(color: StudentTheme.mutedText),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: enabled ? _sendMessage : null,
              style: FilledButton.styleFrom(
                backgroundColor: StudentTheme.blue,
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF333335),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  String get _selectedContactName {
    return _text(_selectedContact?['name'], 'Personal');
  }

  static String _text(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class _Header extends StatelessWidget {
  final String contactName;
  final VoidCallback onClose;

  const _Header({required this.contactName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      color: const Color(0xFF2C2C2E),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: StudentTheme.blue,
            child: Icon(
              Icons.chat_bubble_outline,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat com Personal',
                  style: TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  contactName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: StudentTheme.darkText,
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? sentAt;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.sentAt,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? StudentTheme.blue : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.black : StudentTheme.darkText,
                fontSize: 14,
                height: 1.25,
              ),
            ),
            if (sentAt != null) ...[
              const SizedBox(height: 5),
              Text(
                _formatMessageDate(sentAt!),
                style: TextStyle(
                  color: isMe
                      ? Colors.black.withOpacity(0.58)
                      : StudentTheme.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatMessageDate(DateTime date) {
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == todayOnly) return 'Hoje $time';
    if (messageDay == todayOnly.subtract(const Duration(days: 1))) {
      return 'Ontem $time';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month $time';
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: StudentTheme.mutedText, fontSize: 14),
        ),
      ),
    );
  }
}
