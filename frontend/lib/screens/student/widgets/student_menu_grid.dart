import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentMenuGrid extends StatelessWidget {
  final ValueChanged<int> onOpenSection;

  const StudentMenuGrid({super.key, required this.onOpenSection});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.fitness_center,
        label: 'Treinos',
        onTap: () => onOpenSection(1),
      ),
      _MenuItem(
        icon: Icons.fact_check_outlined,
        label: 'O Meu\nProgresso',
        onTap: () => onOpenSection(5),
      ),
      _MenuItem(
        icon: Icons.restaurant_menu,
        label: 'Plano\nAlimentar',
        onTap: () => onOpenSection(7),
      ),
      _MenuItem(
        icon: Icons.event_available_outlined,
        label: 'Sessões',
        onTap: () => onOpenSection(8),
      ),
      _MenuItem(
        icon: Icons.attach_money,
        label: 'Faturas',
        onTap: () => onOpenSection(4),
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        return _MenuTile(item: items[index]);
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StudentTheme.navy,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: StudentTheme.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: Colors.black, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
