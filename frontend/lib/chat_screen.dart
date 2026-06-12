import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'app_config.dart';
import 'api_service.dart';

class ChatScreen extends StatefulWidget {
  final String token;
  final String role;

  const ChatScreen({super.key, required this.token, required this.role});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? channel;
  int? currentUserId;
  bool _connected = false;
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _selectedContact;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initChat() async {
    final userData = await ApiService.get(context, '/api/v1/profile/me', widget.token);
    if (userData == null || userData['id'] == null) return;
    if (!mounted) return;

    setState(() {
      currentUserId = userData['id'];
    });

    final contacts = await ApiService.get(
      context,
      '/api/v1/my-contacts/',
      widget.token,
    );
    if (!mounted) return;
    if (contacts != null) {
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(contacts);
      });
    }

    if (currentUserId == null) return;

    final uri = AppConfig.websocketUri(
      userId: currentUserId!,
      token: widget.token,
    );
    channel = WebSocketChannel.connect(uri);

    channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          if (data is Map<String, dynamic> && data['type'] == 'message') {
            setState(() {
              _messages.add({
                'text': data['content'],
                'isMe': data['sender_id'] == currentUserId,
                'createdAt': data['created_at'],
              });
            });
            _scrollToBottom();
          } else if (data is Map<String, dynamic> && data['type'] == 'sent') {
            final msg = data['message'];
            setState(() {
              _messages.add({
                'text': msg['content'],
                'isMe': true,
                'createdAt': msg['created_at'],
              });
            });
            _scrollToBottom();
          } else if (data is Map<String, dynamic> && data['detail'] != null) {
            setState(() {
              _messages.add({
                'text': 'Error: ${data['detail']}',
                'isMe': false,
              });
            });
            _scrollToBottom();
          }
        } catch (_) {
          setState(() {
            _messages.add({'text': message.toString(), 'isMe': false});
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        setState(() {
          _messages.add({'text': 'Connection error: $error', 'isMe': false});
        });
      },
      onDone: () {
        setState(() {
          _connected = false;
        });
      },
    );

    setState(() {
      _connected = true;
    });
  }

  Future<void> _loadHistory() async {
    if (_selectedContact == null) return;
    final receiverId = _selectedContact!['id'];
    final history = await ApiService.get(
      context,
      '/api/v1/messages/$receiverId',
      widget.token,
    );
    if (!mounted) return;
    if (history != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(
          List<Map<String, dynamic>>.from(
            history.map(
              (msg) => {
                'text': msg['content'],
                'isMe': msg['sender_id'] == currentUserId,
                'createdAt': msg['created_at'],
              },
            ),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty ||
        _selectedContact == null ||
        currentUserId == null ||
        channel == null) {
      return;
    }

    final receiverId = _selectedContact!['id'];

    final payload = jsonEncode({'receiver_id': receiverId, 'content': text});

    channel!.sink.add(payload);
    _messageController.clear();
  }

  @override
  void dispose() {
    channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == 'trainer') {
      return _buildTrainerChat(context);
    }

    return _buildClassicChat(context);
  }

  Widget _buildClassicChat(BuildContext context) {
    const primaryColor = Color(0xFFD0FD3E);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: const Text(
          'FITPRO Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C2C2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF2C2C2E),
            child: _contacts.isEmpty
                ? const Text(
                    'No contacts yet',
                    style: TextStyle(color: Colors.white54),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedContact,
                      dropdownColor: const Color(0xFF2C2C2E),
                      hint: const Text(
                        'Select a contact',
                        style: TextStyle(color: Colors.white54),
                      ),
                      isExpanded: true,
                      items: _contacts.map((contact) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: contact,
                          child: Text(
                            contact['name'],
                            style: const TextStyle(color: Colors.white),
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
          ),
          Expanded(
            child: _selectedContact == null
                ? const Center(
                    child: Text(
                      'Select a contact to start chatting',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg['isMe']
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: msg['isMe']
                                ? primaryColor
                                : const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: msg['isMe']
                                  ? const Radius.circular(0)
                                  : const Radius.circular(16),
                              bottomLeft: msg['isMe']
                                  ? const Radius.circular(16)
                                  : const Radius.circular(0),
                            ),
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: msg['isMe'] ? Colors.black : Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1C1C1E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    enabled: _connected && _selectedContact != null,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _selectedContact == null
                          ? 'Select a contact first'
                          : _connected
                          ? 'Write a message...'
                          : 'Connecting...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _connected && _selectedContact != null
                        ? _sendMessage
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerChat(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showContactPanel = width >= 760;

    return Scaffold(
      backgroundColor: const Color(0xFF171719),
      appBar: AppBar(
        title: const Text(
          'FITPRO Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C2C2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Row(
        children: [
          if (showContactPanel) _buildTrainerContactPanel(),
          Expanded(
            child: Column(
              children: [
                _buildTrainerConversationHeader(
                  showDropdown: !showContactPanel,
                ),
                Expanded(
                  child: _selectedContact == null
                      ? _buildTrainerEmptyState()
                      : _buildTrainerMessages(),
                ),
                _buildTrainerComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerContactPanel() {
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: Color(0xFF202023),
        border: Border(right: BorderSide(color: Color(0xFF333336))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    'Conversas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.white70),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.white54),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Procurar aluno',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _contacts.isEmpty
                ? const Center(
                    child: Text(
                      'Sem contactos ainda',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final selected = _selectedContact?['id'] == contact['id'];
                      return _buildTrainerContactTile(contact, selected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerContactTile(Map<String, dynamic> contact, bool selected) {
    final name = (contact['name'] ?? 'Aluno').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selectedContact = contact;
          _messages.clear();
        });
        _loadHistory();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2C2C2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD0FD3E),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toque para abrir a conversa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerConversationHeader({required bool showDropdown}) {
    final name = (_selectedContact?['name'] ?? 'Selecione um aluno').toString();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        border: Border(bottom: BorderSide(color: Color(0xFF333336))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _selectedContact == null
                ? const Color(0xFF3A3A3C)
                : const Color(0xFFD0FD3E),
            child: Text(
              _selectedContact == null ? '?' : _initials(name),
              style: TextStyle(
                color: _selectedContact == null ? Colors.white70 : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: showDropdown
                ? _buildTrainerContactDropdown()
                : _buildHeaderName(name),
          ),
          IconButton(
            tooltip: 'Pesquisar',
            onPressed: null,
            icon: const Icon(Icons.search),
            color: Colors.white54,
            disabledColor: Colors.white38,
          ),
          IconButton(
            tooltip: 'Mais opcoes',
            onPressed: null,
            icon: const Icon(Icons.more_vert),
            color: Colors.white54,
            disabledColor: Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderName(String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _connected ? 'Online' : 'A ligar...',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTrainerContactDropdown() {
    if (_contacts.isEmpty) {
      return const Text(
        'Sem contactos ainda',
        style: TextStyle(color: Colors.white54),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<Map<String, dynamic>>(
        value: _selectedContact,
        dropdownColor: const Color(0xFF2C2C2E),
        hint: const Text(
          'Selecionar aluno',
          style: TextStyle(color: Colors.white54),
        ),
        isExpanded: true,
        items: _contacts.map((contact) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: contact,
            child: Text(
              contact['name'],
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
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
    );
  }

  Widget _buildTrainerEmptyState() {
    return const Center(
      child: Text(
        'Escolha um aluno para iniciar a conversa',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }

  Widget _buildTrainerMessages() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF171719)),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return _buildTrainerMessageBubble(msg);
        },
      ),
    );
  }

  Widget _buildTrainerMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true;
    final maxWidth = MediaQuery.of(context).size.width * 0.54;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(260.0, 620.0)),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFD0FD3E) : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 3),
              bottomRight: Radius.circular(isMe ? 3 : 14),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg['text'].toString(),
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _messageDateTime(msg['createdAt']),
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 15, color: Colors.black54),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainerComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      color: const Color(0xFF202023),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Adicionar',
              onPressed: null,
              icon: const Icon(Icons.add),
              color: Colors.white54,
              disabledColor: Colors.white38,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                enabled: _connected && _selectedContact != null,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: _selectedContact == null
                      ? 'Selecione um aluno'
                      : _connected
                      ? 'Escrever mensagem'
                      : 'A ligar...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFD0FD3E),
              child: IconButton(
                tooltip: 'Enviar',
                icon: const Icon(Icons.send, color: Colors.black),
                onPressed: _connected && _selectedContact != null
                    ? _sendMessage
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  String _messageDateTime(dynamic rawDate) {
    if (rawDate is! String || rawDate.isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final difference = todayOnly.difference(messageDay).inDays;

    if (difference == 0) return 'Hoje $hour:$minute';
    if (difference == 1) return 'Ontem $hour:$minute';

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
