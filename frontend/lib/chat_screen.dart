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
  final TextEditingController _receiverController = TextEditingController();

  WebSocketChannel? channel;
  int? currentUserId;
  bool _connected = false;
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final userData = await ApiService.get(context, '/me', widget.token);
    if (userData == null || userData['id'] == null) return;

    setState(() {
      currentUserId = userData['id'];
    });

    final uri = Uri.parse('ws://10.0.2.2:8000/ws/$currentUserId?token=${widget.token}');
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
        } else if (data is Map<String, dynamic> && data['type'] == 'sent') {
          // Mensagem já é mostrada localmente no envio.
        } else if (data is Map<String, dynamic> && data['detail'] != null) {
          setState(() {
            _messages.add({
              'text': 'Erro: ${data['detail']}',
              'isMe': false,
            });
          });
        } else {
          setState(() {
            _messages.add({
              'text': message.toString(),
              'isMe': false,
            });
          });
        }
      } catch (_) {
        setState(() {
          _messages.add({
            'text': message.toString(),
            'isMe': false,
          });
        });
      }
    }, onError: (error) {
      setState(() {
        _messages.add({
          'text': 'Erro de conexão: $error',
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    final receiverText = _receiverController.text.trim();

    if (text.isEmpty || receiverText.isEmpty || currentUserId == null || channel == null) return;

    final receiverId = int.tryParse(receiverText);
    if (receiverId == null) return;

    final payload = jsonEncode({
      'receiver_id': receiverId,
      'content': text,
    });

    channel!.sink.add(payload);

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
      });
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    channel?.sink.close();
    _messageController.dispose();
    _receiverController.dispose();
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _receiverController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Receiver ID',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currentUserId != null ? 'You: $currentUserId' : 'A carregar...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                return Align(
                  alignment: msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg['isMe'] ? primaryColor : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg['isMe'] ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: msg['isMe'] ? const Radius.circular(16) : const Radius.circular(0),
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
                    decoration: InputDecoration(
                      hintText: _connected ? 'Escreve uma mensagem...' : 'A conectar...',
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
                    enabled: _connected,
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _connected ? _sendMessage : null,
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
