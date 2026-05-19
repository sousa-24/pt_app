import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  final String token;

  const FeedScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    // Cores alinhadas com o estilo escuro/neon da app
    const backgroundColor = Color(0xFF1C1C1E);
    const cardColor = Color(0xFF2C2C2E);
    const accentColor = Color(0xFFD0FD3E); // Verde Neon FITPRO

    // Lista simulada com dados que futuramente virão da Base de Dados
    final List<Map<String, dynamic>> feedItems = [
      {
        'type': 'challenge',
        'title': 'Desafio Superação Semanal',
        'subtitle': 'Concluir 4 treinos de alta intensidade esta semana.',
        'progress': 0.75,
        'status': '3/4 Treinos',
      },
      {
        'type': 'tip',
        'title': 'Dica de Nutrição do PT',
        'subtitle': 'A hidratação pós-treino acelera a recuperação muscular em até 20%. Mantém a garrafa de água por perto!',
        'progress': 1.0,
        'status': 'Dica do Dia',
      },
      {
        'type': 'challenge',
        'title': 'Meta Absorção de Água',
        'subtitle': 'Bater a meta diária de 3L de água por 5 dias seguidos.',
        'progress': 0.40,
        'status': '2/5 Dias',
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'FITPRO Feed & Desafios',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feedItems.length,
        itemBuilder: (context, index) {
          final item = feedItems[index];
          final isChallenge = item['type'] == 'challenge';

          return Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        isChallenge ? Icons.emoji_events : Icons.lightbulb,
                        color: accentColor,
                        size: 28,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isChallenge ? Colors.black38 : accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: isChallenge ? Colors.white70 : accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['subtitle'],
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (isChallenge) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: item['progress'],
                      backgroundColor: Colors.black26,
                      color: accentColor,
                      minHeight: 6,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}