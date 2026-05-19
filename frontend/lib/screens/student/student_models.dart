import 'package:flutter/material.dart';

class StudentWorkoutPlan {
  final String id;
  final String title;
  final String focus;
  final int weekday;
  final int durationMinutes;
  final List<String> exercises;
  final Color color;
  final IconData icon;

  const StudentWorkoutPlan({
    required this.id,
    required this.title,
    required this.focus,
    required this.weekday,
    required this.durationMinutes,
    required this.exercises,
    required this.color,
    required this.icon,
  });
}

class StudentDateLabels {
  const StudentDateLabels._();

  static String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String monthTitle(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Marco',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return months[date.month - 1];
  }

  static String weekdayShort(int weekday) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    return days[weekday - 1];
  }

  static String weekdayFull(int weekday) {
    const days = [
      'segunda',
      'terca',
      'quarta',
      'quinta',
      'sexta',
      'sabado',
      'domingo',
    ];
    return days[weekday - 1];
  }
}
