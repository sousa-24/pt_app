import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentProfileCard extends StatelessWidget {
  const StudentProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perfil do aluno',
            style: TextStyle(
              color: StudentTheme.darkText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _InfoRow(icon: Icons.person_outline, label: 'Aluno', value: 'Alex'),
          _InfoRow(
            icon: Icons.supervisor_account_outlined,
            label: 'Personal',
            value: 'Mariana Fit',
          ),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Objetivo',
            value: 'Ganhar condicionamento',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, color: StudentTheme.blue),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: StudentTheme.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: StudentTheme.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
