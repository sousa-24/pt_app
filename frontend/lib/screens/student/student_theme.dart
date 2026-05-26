import 'package:flutter/material.dart';

class StudentTheme {
  const StudentTheme._();

  static const double maxContentWidth = 460;

  static const Color blue = Color.fromARGB(223, 212, 244, 74);
  static const Color navy = Color(0xFF252527);
  static const Color darkNavy = Color(0xFF1C1C1E);
  static const Color darkText = Color(0xFFF3F3EA);
  static const Color lightBg = Color(0xFF1C1C1E);
  static const Color mutedText = Color(0xFFA7A7A0);

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF3A3A3D)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 14,
          offset: Offset(0, 7),
        ),
      ],
    );
  }
}
