import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onOpenChat;

  const StudentBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavConfig(Icons.home_rounded, 'Inicio'),
      _NavConfig(Icons.fitness_center, 'Treinos'),
      _NavConfig(Icons.chat_bubble_outline, 'Chat'),
      _NavConfig(Icons.menu_rounded, 'Menu'),
    ];

    return Container(
      height: 88,
      decoration: const BoxDecoration(color: Color(0xFF151516)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = selectedIndex == index;

          return InkWell(
            onTap: index == 2 ? onOpenChat : () => onChanged(index),
            child: SizedBox(
              width: 82,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isActive
                        ? StudentTheme.blue
                        : Colors.white.withOpacity(0.72),
                    size: 30,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive
                          ? StudentTheme.blue
                          : Colors.white.withOpacity(0.76),
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavConfig {
  final IconData icon;
  final String label;

  const _NavConfig(this.icon, this.label);
}
