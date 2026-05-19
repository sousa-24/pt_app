import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentHeader extends StatelessWidget {
  const StudentHeader({super.key});

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
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: StudentTheme.blue,
                  size: 30,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'FITPRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Stack(
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
              ],
            ),
            const SizedBox(height: 34),
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
            const Text(
              'bruna cardoso raimondi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Boa tarde, Alex!',
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
}
