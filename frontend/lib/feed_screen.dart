import 'package:flutter/material.dart';

import 'l10n/gen/app_localizations.dart';

class FeedScreen extends StatelessWidget {
  final String token;

  const FeedScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Cores alinhadas com o estilo escuro/neon da app
    const backgroundColor = Color(0xFF1C1C1E);
    const cardColor = Color(0xFF2C2C2E);
    const accentColor = Color(0xFFD0FD3E); // Verde Neon FITPRO

    // Lista simulada com dados que futuramente virão da Base de Dados
    final List<Map<String, dynamic>> feedItems = [
      {
        'type': 'challenge',
        'title': l10n.feedChallengeWeeklyTitle,
        'subtitle': l10n.feedChallengeWeeklySubtitle,
        'progress': 0.75,
        'status': l10n.feedChallengeWeeklyStatus,
      },
      {
        'type': 'tip',
        'title': l10n.feedTipTitle,
        'subtitle': l10n.feedTipSubtitle,
        'progress': 1.0,
        'status': l10n.feedTipStatus,
      },
      {
        'type': 'challenge',
        'title': l10n.feedWaterGoalTitle,
        'subtitle': l10n.feedWaterGoalSubtitle,
        'progress': 0.40,
        'status': l10n.feedWaterGoalStatus,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.feedScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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