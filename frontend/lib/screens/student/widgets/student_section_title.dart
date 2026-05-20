import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const StudentSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: StudentTheme.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: StudentTheme.blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
