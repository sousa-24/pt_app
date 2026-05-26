import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_service.dart';
import '../../main.dart';
import 'student_models.dart';
import 'student_theme.dart';
import 'widgets/student_bottom_nav.dart';
import 'widgets/student_calendar_card.dart';
import 'widgets/student_floating_chat.dart';
import 'widgets/student_frequency_card.dart';
import 'widgets/student_header.dart';
import 'widgets/student_hydration_card.dart';
import 'widgets/student_invoices_screen.dart';
import 'widgets/student_menu_grid.dart';
import 'widgets/student_menu_screen.dart';
import 'widgets/student_nutrition_plan_screen.dart';
import 'widgets/student_progress_screen.dart';
import 'widgets/student_profile_card.dart';
import 'widgets/student_section_title.dart';
import 'widgets/student_workout_card.dart';

class StudentHomeScreen extends StatefulWidget {
  final String? token;
  final String role;
  final VoidCallback? onToggleTheme;
  final ThemeMode themeMode;

  const StudentHomeScreen({
    super.key,
    this.token,
    this.role = 'client',
    this.onToggleTheme,
    this.themeMode = ThemeMode.dark,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<StudentWorkoutPlan> _workouts = [];
  List<StudentTrainingSession> _trainingSessions = [];
  final Set<String> _completedWorkoutIds = {'lower-a'};
  bool _isLoadingWorkouts = true;
  String? _workoutErrorMessage;
  int _selectedNavIndex = 0;
  String _studentName = 'Aluno';
  late DateTime _selectedDate;
  bool _isChatOpen = false;
  int _waterMl = 0;
  static const int _waterGoalMl = 2000;
  static const String _hydrationDateKey = 'fitpro_hydration_date';
  static const String _hydrationAmountKey = 'fitpro_hydration_amount_ml';

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _loadHydration();
    _loadStudentData();
    _loadWorkoutPlans();
    _loadTrainingSessions();
  }

  @override
  Widget build(BuildContext context) {
    final isMenuArea = _selectedNavIndex == 3;

    return Scaffold(
      backgroundColor: StudentTheme.lightBg,
      bottomNavigationBar: isMenuArea ? null : _bottomNav(),
      body: Stack(
        children: [
          _studentPage(isMenuArea),
          if (_isChatOpen) _floatingChat(),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: StudentTheme.maxContentWidth,
        ),
        child: StudentBottomNav(
          selectedIndex: _selectedNavIndex,
          onChanged: (index) => setState(() => _selectedNavIndex = index),
          onOpenChat: _openChat,
        ),
      ),
    );
  }

  Widget _studentPage(bool isMenuArea) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: StudentTheme.maxContentWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMenuArea) StudentHeader(studentName: _studentName),
              Transform.translate(
                offset: Offset(0, isMenuArea ? 0 : -18),
                child: SafeArea(
                  top: isMenuArea,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isMenuArea ? 18 : 0,
                      20,
                      24,
                    ),
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
      ),
    );
  }

  List<Widget> _selectedContent() {
    if (_selectedNavIndex == 0) {
      return [
        StudentFrequencyCard(
          workouts: _workouts,
          trainingSessions: _trainingSessions,
          selectedDate: _selectedDate,
          onWeekdaySelected: _selectWeekday,
        ),
        const SizedBox(height: 18),
        StudentHydrationCard(
          currentMl: _waterMl,
          goalMl: _waterGoalMl,
          onAddSmall: () => _addWater(250),
          onAddMedium: () => _addWater(500),
          onRemoveSmall: () => _removeWater(250),
          onReset: _resetWater,
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
        if (_isLoadingWorkouts)
          const Center(child: CircularProgressIndicator())
        else if (_workoutErrorMessage != null)
          _StatusCard(message: _workoutErrorMessage!)
        else if (_workouts.isEmpty)
          const _StatusCard(
            message: 'Ainda nao existem treinos atribuidos.',
          )
        else
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
      return [StudentProgressScreen(token: widget.token)];
    }

    if (_selectedNavIndex == 6) {
      return const [StudentProfileCard()];
    }

    if (_selectedNavIndex == 7) {
      return [StudentNutritionPlanScreen(token: widget.token)];
    }

    return [
      StudentMenuScreen(
        studentName: _studentName,
        onBack: () => setState(() => _selectedNavIndex = 0),
        onLogout: _logout,
        onOpenChat: _openChat,
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
    final selectedDate = _dateOnly(date);

    return _workouts.where((workout) {
      final scheduledDate = workout.scheduledDate;
      if (scheduledDate != null) {
        return _dateOnly(scheduledDate) == selectedDate;
      }

      return workout.weekday == date.weekday;
    }).toList();
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

  void _addWater(int amountMl) {
    if (_waterMl >= _waterGoalMl) return;

    setState(() {
      _waterMl = (_waterMl + amountMl).clamp(0, _waterGoalMl).toInt();
    });
    _saveHydration();

    if (_waterMl == _waterGoalMl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meta de hidratacao concluida hoje.'),
        ),
      );
    }
  }

  void _removeWater(int amountMl) {
    if (_waterMl <= 0) return;

    setState(() {
      _waterMl = (_waterMl - amountMl).clamp(0, _waterGoalMl).toInt();
    });
    _saveHydration();
  }

  void _resetWater() {
    setState(() => _waterMl = 0);
    _saveHydration();
  }

  Future<void> _loadHydration() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString(_hydrationDateKey);
    final savedAmount = prefs.getInt(_hydrationAmountKey);

    if (savedDate == today && savedAmount != null) {
      if (!mounted) return;
      setState(() {
        _waterMl = savedAmount.clamp(0, _waterGoalMl).toInt();
      });
      return;
    }

    await prefs.setString(_hydrationDateKey, today);
    await prefs.setInt(_hydrationAmountKey, 0);
    if (!mounted) return;
    setState(() => _waterMl = 0);
  }

  Future<void> _saveHydration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hydrationDateKey, _todayKey());
    await prefs.setInt(_hydrationAmountKey, _waterMl);
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _loadStudentData() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    final userData = await ApiService.get(context, '/api/v1/me', token);
    if (!mounted || userData == null) return;

    final name = userData['name'];
    if (name is String && name.trim().isNotEmpty) {
      setState(() {
        _studentName = name.trim();
      });
    }
  }

  Future<void> _loadWorkoutPlans() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingWorkouts = false;
        _workoutErrorMessage = 'Entre com login para acessar os treinos.';
      });
      return;
    }

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/workout_plans/',
        token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        if (data is List) {
          _workouts = List.generate(
            data.length,
            (index) => _workoutFromApi(data[index], index),
          );
        }
        _isLoadingWorkouts = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _workoutErrorMessage =
            'Nao foi possivel carregar os treinos agora.';
        _isLoadingWorkouts = false;
      });
    }
  }

  Future<void> _loadTrainingSessions() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/training_sessions/',
        token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted || data is! List) return;

      setState(() {
        _trainingSessions = data
            .map(_trainingSessionFromApi)
            .whereType<StudentTrainingSession>()
            .toList();
        _workouts = _workouts.map(_workoutWithSessionDate).toList();
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  StudentWorkoutPlan _workoutFromApi(dynamic value, int index) {
    final plan = value is Map<String, dynamic> ? value : <String, dynamic>{};
    final exercisesData =
        plan['exercises'] is List ? plan['exercises'] as List : const [];
    final exercises =
        exercisesData
            .whereType<Map<String, dynamic>>()
            .map((exercise) {
              final name = _text(exercise['name'], 'Exercicio');
              final sets = exercise['sets'];
              final reps = exercise['reps'];

              if (sets == null || reps == null) return name;
              return '$name ${sets}x$reps';
            })
            .toList();

    return StudentWorkoutPlan(
      id: _text(plan['id'], 'workout-$index'),
      title: _text(plan['title'], 'Treino ${index + 1}'),
      focus:
          exercises.isEmpty
              ? 'Plano atribuido'
              : '${exercises.length} exercicios',
      weekday: (index % 7) + 1,
      scheduledDate:
          _sessionDateForWorkout(_text(plan['id'], 'workout-$index')),
      durationMinutes: exercises.isEmpty ? 0 : exercises.length * 10,
      exercises: exercises,
      color: _workoutColor(index),
      icon: Icons.fitness_center,
    );
  }

  StudentWorkoutPlan _workoutWithSessionDate(StudentWorkoutPlan workout) {
    final sessionDate = _sessionDateForWorkout(workout.id);
    if (sessionDate == null) return workout;

    return StudentWorkoutPlan(
      id: workout.id,
      title: workout.title,
      focus: workout.focus,
      weekday: sessionDate.weekday,
      scheduledDate: sessionDate,
      durationMinutes: workout.durationMinutes,
      exercises: workout.exercises,
      color: workout.color,
      icon: workout.icon,
    );
  }

  DateTime? _sessionDateForWorkout(String workoutId) {
    for (final session in _trainingSessions) {
      if (session.workoutPlanId == workoutId) {
        return session.date;
      }
    }

    return null;
  }

  StudentTrainingSession? _trainingSessionFromApi(dynamic value) {
    final session = value is Map<String, dynamic> ? value : null;
    if (session == null) return null;

    final rawDate = session['date'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (date == null) return null;

    return StudentTrainingSession(
      id: _text(session['id'], 'session-${_trainingSessions.length}'),
      workoutPlanId: session['workout_plan_id']?.toString(),
      date: date,
      status: _text(session['status'], 'scheduled'),
    );
  }

  void _openChat() {
    final token = widget.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre com login para acessar o chat.'),
        ),
      );
      return;
    }

    setState(() => _isChatOpen = true);
  }

  Widget _floatingChat() {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 700;

    return Positioned(
      right: isCompact ? 12 : 24,
      bottom: isCompact ? 12 : 24,
      child: StudentFloatingChat(
        token: widget.token!,
        onClose: () => setState(() => _isChatOpen = false),
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onToggleTheme: widget.onToggleTheme ?? () {},
          themeMode: widget.themeMode,
        ),
      ),
      (route) => false,
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static Color _workoutColor(int index) {
    const colors = [
      StudentTheme.blue,
      Color(0xFFFF7A00),
      Color(0xFF20A36B),
      Color(0xFF4EA6FF),
    ];

    return colors[index % colors.length];
  }

  static String _text(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class _StatusCard extends StatelessWidget {
  final String message;

  const _StatusCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Text(
        message,
        style: const TextStyle(
          color: StudentTheme.mutedText,
          fontSize: 14,
        ),
      ),
    );
  }
}
