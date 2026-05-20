import 'package:flutter/material.dart';

import 'student_models.dart';
import 'student_theme.dart';
import 'widgets/student_bottom_nav.dart';
import 'widgets/student_calendar_card.dart';
import 'widgets/student_frequency_card.dart';
import 'widgets/student_header.dart';
import 'widgets/student_invoices_screen.dart';
import 'widgets/student_menu_grid.dart';
import 'widgets/student_menu_screen.dart';
import 'widgets/student_profile_card.dart';
import 'widgets/student_section_title.dart';
import 'widgets/student_workout_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final List<StudentWorkoutPlan> _workouts = const [
    StudentWorkoutPlan(
      id: 'lower-a',
      title: 'Treino A',
      focus: 'Pernas e gluteos',
      weekday: DateTime.monday,
      durationMinutes: 45,
      exercises: ['Agachamento', 'Leg press', 'Cadeira extensora'],
      color: StudentTheme.blue,
      icon: Icons.fitness_center,
    ),
    StudentWorkoutPlan(
      id: 'upper-b',
      title: 'Treino B',
      focus: 'Peito, costas e bracos',
      weekday: DateTime.wednesday,
      durationMinutes: 50,
      exercises: ['Supino', 'Remada baixa', 'Desenvolvimento'],
      color: Color(0xFFFF7A00),
      icon: Icons.sports_gymnastics,
    ),
    StudentWorkoutPlan(
      id: 'full-c',
      title: 'Treino C',
      focus: 'Corpo inteiro',
      weekday: DateTime.friday,
      durationMinutes: 40,
      exercises: ['Levantamento terra', 'Afundo', 'Prancha'],
      color: Color(0xFF20A36B),
      icon: Icons.directions_run,
    ),
  ];

  final Set<String> _completedWorkoutIds = {'lower-a'};
  int _selectedNavIndex = 0;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isMenuArea = _selectedNavIndex == 3;

    return Scaffold(
      backgroundColor: StudentTheme.lightBg,
      bottomNavigationBar:
          isMenuArea
              ? null
              : StudentBottomNav(
                selectedIndex: _selectedNavIndex,
                onChanged: (index) => setState(() => _selectedNavIndex = index),
              ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMenuArea) const StudentHeader(),
            Transform.translate(
              offset: Offset(0, isMenuArea ? 0 : -18),
              child: SafeArea(
                top: isMenuArea,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, isMenuArea ? 18 : 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _selectedContent() {
    if (_selectedNavIndex == 0) {
      return [
        StudentFrequencyCard(
          workouts: _workouts,
          selectedDate: _selectedDate,
          onWeekdaySelected: _selectWeekday,
        ),
        const SizedBox(height: 18),
        StudentMenuGrid(
          onOpenSection: (index) => setState(() => _selectedNavIndex = index),
        ),
      ];
    }

    if (_selectedNavIndex == 1) {
      return [
        const StudentSectionTitle(
          title: 'Treinos da personal',
          subtitle: 'Plano semanal',
        ),
        const SizedBox(height: 12),
        ..._workouts.map(_workoutCard),
      ];
    }

    if (_selectedNavIndex == 2) {
      return [
        StudentCalendarCard(
          selectedDate: _selectedDate,
          completedWorkoutIds: _completedWorkoutIds,
          plansForDate: _plansForDate,
          onDateSelected: _selectCalendarDate,
        ),
        const SizedBox(height: 20),
        _selectedDayWorkouts(),
      ];
    }

    if (_selectedNavIndex == 4) {
      return const [StudentInvoicesScreen()];
    }

    if (_selectedNavIndex == 5) {
      return const [StudentProfileCard()];
    }

    if (_selectedNavIndex == 6) {
      return const [StudentProfileCard()];
    }

    return [
      StudentMenuScreen(
        onBack: () => setState(() => _selectedNavIndex = 0),
        onLogout: () => Navigator.of(context).maybePop(),
        onOpenSection: (index) => setState(() => _selectedNavIndex = index),
      ),
    ];
  }

  Widget _selectedDayWorkouts() {
    final plans = _plansForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentSectionTitle(
          title:
              'Treinos de ${StudentDateLabels.weekdayFull(_selectedDate.weekday)}',
          subtitle: StudentDateLabels.dateLabel(_selectedDate),
        ),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: StudentTheme.cardDecoration(),
            child: const Text(
              'Sem treino marcado para este dia.',
              style: TextStyle(
                color: StudentTheme.mutedText,
                fontSize: 14,
              ),
            ),
          )
        else
          ...plans.map(_workoutCard),
      ],
    );
  }

  Widget _workoutCard(StudentWorkoutPlan workout) {
    return StudentWorkoutCard(
      workout: workout,
      isCompleted: _completedWorkoutIds.contains(workout.id),
      onToggle: () => _toggleWorkout(workout),
    );
  }

  List<StudentWorkoutPlan> _plansForDate(DateTime date) {
    return _workouts.where((workout) => workout.weekday == date.weekday).toList();
  }

  void _selectWeekday(int weekday) {
    final now = DateTime.now();
    final difference = weekday - now.weekday;

    setState(() {
      _selectedDate = _dateOnly(now.add(Duration(days: difference)));
    });
  }

  void _selectCalendarDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _selectedNavIndex = 2;
    });
  }

  void _toggleWorkout(StudentWorkoutPlan workout) {
    setState(() {
      if (_completedWorkoutIds.contains(workout.id)) {
        _completedWorkoutIds.remove(workout.id);
      } else {
        _completedWorkoutIds.add(workout.id);
      }
    });
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
