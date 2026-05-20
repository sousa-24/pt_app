import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentMenuScreen extends StatelessWidget {
  final ValueChanged<int> onOpenSection;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const StudentMenuScreen({
    super.key,
    required this.onOpenSection,
    required this.onBack,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuRowItem(
        icon: Icons.edit_outlined,
        label: 'Editar Perfil',
        onTap: () => onOpenSection(6),
      ),
      _MenuRowItem(
        icon: Icons.fitness_center,
        label: 'Treinos',
        onTap: () => onOpenSection(1),
      ),
      _MenuRowItem(
        icon: Icons.assignment_outlined,
        label: 'Avaliações',
        onTap: () {},
      ),
      _MenuRowItem(
        icon: Icons.fact_check_outlined,
        label: 'O Meu Progresso',
        onTap: () => onOpenSection(5),
      ),
      _MenuRowItem(
        icon: Icons.note_add_outlined,
        label: 'Treinos Extra',
        onTap: () => onOpenSection(1),
      ),
      _MenuRowItem(
        icon: Icons.attach_money,
        label: 'Faturas',
        onTap: () => onOpenSection(4),
      ),
      _MenuRowItem(
        icon: Icons.folder_outlined,
        label: 'Ficheiros',
        onTap: () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Voltar'),
          style: TextButton.styleFrom(
            foregroundColor: StudentTheme.darkText,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(70),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opcao para inserir foto do aluno.'),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: StudentTheme.blue, width: 4),
                    color: const Color(0xFF2C2C2E),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: StudentTheme.mutedText,
                    size: 74,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: StudentTheme.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.black,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Inserir foto',
            style: TextStyle(
              color: StudentTheme.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Alex Oliveira da Silva',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StudentTheme.darkText,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: StudentTheme.cardDecoration(),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return _MenuRow(
                item: item,
                showDivider: !isLast,
              );
            }),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Sair',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: StudentTheme.blue,
              side: const BorderSide(color: StudentTheme.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _MenuRowItem item;
  final bool showDivider;

  const _MenuRow({
    required this.item,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: item.onTap,
          leading: Icon(
            item.icon,
            color: StudentTheme.darkText,
          ),
          title: Text(item.label),
          textColor: StudentTheme.darkText,
          iconColor: StudentTheme.darkText,
          titleTextStyle: const TextStyle(
            color: StudentTheme.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minLeadingWidth: 33,
          trailing: const Icon(
            Icons.chevron_right,
            color: StudentTheme.mutedText,
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 65,
            endIndent: 16,
            color: Color(0xFF3A3A3D),
          ),
      ],
    );
  }
}

class _MenuRowItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRowItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
