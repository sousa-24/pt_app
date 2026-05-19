import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String token;
  final String role;

  const ChatScreen({super.key, required this.token, required this.role});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Olá! Como correu o treino de pernas hoje?', 'isMe': false},
    {'text': 'Correu bem! Senti um bocado de cansaço no agachamento final.', 'isMe': true},
    {'text': 'Normal para a primeira semana. Ajustamos a carga amanhã!', 'isMe': false},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'text': _messageController.text,
          'isMe': true, 
        });
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD0FD3E); 

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), 
      appBar: AppBar(
        title: const Text('FITPRO Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2C2C2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
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
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                      hintText: 'Escreve uma mensagem...',
                      hintStyle: const TextStyle(color: Colors.white54), // Correção aqui!
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
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