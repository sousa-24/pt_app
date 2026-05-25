import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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
    final userData = await ApiService.get(context, '/api/v1/me', widget.token);
    if (userData == null || userData['id'] == null) return;

    setState(() {
      currentUserId = userData['id'];
    });

    final contacts = await ApiService.get(context, '/api/v1/my-contacts/', widget.token);
    if (contacts != null) {
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(contacts);
      });
    }

    if (currentUserId == null) return;

    final uri = Uri.parse('ws://127.0.0.1:8000/ws/$currentUserId?token=${widget.token}');
    channel = WebSocketChannel.connect(uri);

    channel!.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        if (data is Map<String, dynamic> && data['type'] == 'message') {
          setState(() {
            _messages.add({
              'text': data['content'],
              'isMe': data['sender_id'] == currentUserId,
            });
          });
          _scrollToBottom();
        } else if (data is Map<String, dynamic> && data['type'] == 'sent') {
          final msg = data['message'];
          setState(() {
            _messages.add({
              'text': msg['content'],
              'isMe': true,
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
          _messages.add({
            'text': message.toString(),
            'isMe': false,
          });
        });
        _scrollToBottom();
      }
    }, onError: (error) {
      setState(() {
        _messages.add({
          'text': 'Connection error: $error',
          'isMe': false,
        });
      });
    }, onDone: () {
      setState(() {
        _connected = false;
      });
    });

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
    if (history != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(List<Map<String, dynamic>>.from(
          history.map((msg) => {
            'text': msg['content'],
            'isMe': msg['sender_id'] == currentUserId,
          }),
        ));
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedContact == null || currentUserId == null || channel == null) return;

    final receiverId = _selectedContact!['id'];

    final payload = jsonEncode({
      'receiver_id': receiverId,
      'content': text,
    });

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
}