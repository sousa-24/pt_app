import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentHeader extends StatelessWidget {
  final String studentName;

  const StudentHeader({
    super.key,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
      decoration: const BoxDecoration(
        color: StudentTheme.darkNavy,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: StudentTheme.blue,
                      size: 44,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'FITPRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton.filled(
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Color(0xFF2C2C2E),
                          foregroundColor: StudentTheme.blue,
                        ),
                        icon: const Icon(Icons.notifications_none),
                      ),
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7185),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: StudentTheme.blue, width: 4),
                color: Color(0xFF2C2C2E),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFFA7A7A0),
                size: 74,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              studentName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Boa tarde, ${_firstName(studentName)}!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Aluno';
    return trimmed.split(' ').first;
  }
}
