import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../main.dart';
import 'student_models.dart';
import 'student_theme.dart';
import 'widgets/student_bottom_nav.dart';
import 'widgets/student_floating_chat.dart';
import 'widgets/student_header.dart';
import 'widgets/student_hydration_card.dart';
import 'widgets/student_invoices_screen.dart';
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
  List<StudentTrainingSession> _enrolledGroupSessions = [];
  List<StudentTrainingSession> _availableGroupSessions = [];
  final Set<String> _completedWorkoutIds = {'lower-a'};
  bool _isLoadingWorkouts = true;
  String? _workoutErrorMessage;
  int _selectedNavIndex = 0;
  String _studentName = '';
  String _studentEmail = '';
  String? _profilePictureUrl;
  bool _isProfileDetailView = false;
  bool _isUploadingProfilePicture = false;
  int _profileBackRequest = 0;
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
    _loadEnrolledGroupSessions();
    _loadAvailableGroupSessions();
  }

  @override
  Widget build(BuildContext context) {
    final isMenuArea = _selectedNavIndex == 3;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: StudentTheme.lightBg,
      bottomNavigationBar: _bottomNav(),
      body: Stack(
        children: [
          _studentPage(isMenuArea, l10n),
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
          onChanged: _openSection,
          onOpenChat: _openChat,
        ),
      ),
    );
  }

  Widget _studentPage(bool isMenuArea, AppLocalizations l10n) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: StudentTheme.maxContentWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMenuArea)
                StudentHeader(
                  studentName: _studentName.isEmpty ? l10n.accountStudent : _studentName,
                  profilePictureUrl: _profilePictureUrl,
                  token: widget.token,
                  showGreeting: _selectedNavIndex != 6,
                  showEditPhotoAction: _selectedNavIndex == 6,
                  isUploadingProfilePicture: _isUploadingProfilePicture,
                  onBack: _selectedNavIndex != 0
                      ? () => setState(() {
                            if (_selectedNavIndex == 6 &&
                                _isProfileDetailView) {
                              _profileBackRequest++;
                              _isProfileDetailView = false;
                            } else {
                              _selectedNavIndex = 0;
                            }
                          })
                      : null,
                  onProfilePictureTap: () {
                    if (_selectedNavIndex == 6) {
                      _pickAndUploadProfilePicture();
                    } else {
                      setState(() {
                        _selectedNavIndex = 6;
                        _isProfileDetailView = false;
                      });
                    }
                  },
                  onNotificationTap: (type) {
                    if (type == 'message') {
                      _openChat();
                    } else if (type == 'training_session') {
                      setState(() => _selectedNavIndex = 8);
                    }
                  },
                ),
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
                      children: _selectedContent(l10n),
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

  List<Widget> _selectedContent(AppLocalizations l10n) {
    if (_selectedNavIndex == 0) {
      return [
        _homeSummaryCards(),
        const SizedBox(height: 18),
        _todayHighlightCard(),
        const SizedBox(height: 18),
        StudentHydrationCard(
          currentMl: _waterMl,
          goalMl: _waterGoalMl,
          onAddSmall: () => _addWater(250),
          onAddMedium: () => _addWater(500),
          onRemoveSmall: () => _removeWater(250),
          onReset: _resetWater,
        ),
      ];
    }

    if (_selectedNavIndex == 1) {
      return [
        StudentSectionTitle(
          title: l10n.trainerWorkoutsTitle,
          subtitle: l10n.weeklyPlanSubtitle,
        ),
        const SizedBox(height: 12),
        if (_isLoadingWorkouts)
          const Center(child: CircularProgressIndicator())
        else if (_workoutErrorMessage != null)
          _StatusCard(message: _workoutErrorMessage!)
        else if (_workouts.isEmpty)
          _StatusCard(message: l10n.noWorkoutsAssignedMessage)
        else
          ..._workouts.map(_workoutCard),
      ];
    }

    if (_selectedNavIndex == 4) {
      return [StudentInvoicesScreen(token: widget.token)];
    }

    if (_selectedNavIndex == 5) {
      return [StudentProgressScreen(token: widget.token)];
    }

    if (_selectedNavIndex == 6) {
      return [
        StudentProfileCard(
          token: widget.token,
          name: _studentName,
          email: _studentEmail,
          onProfileUpdated: _applyProfileData,
          backRequest: _profileBackRequest,
          onDetailViewChanged: (isDetailView) {
            setState(() => _isProfileDetailView = isDetailView);
          },
        ),
      ];
    }

    if (_selectedNavIndex == 7) {
      return [StudentNutritionPlanScreen(token: widget.token)];
    }

    if (_selectedNavIndex == 8) {
      return [
        StudentSectionTitle(
          title: l10n.mySessionsTitle,
          subtitle: l10n.sessionsScheduledByTrainerSubtitle,
        ),
        const SizedBox(height: 12),
        if (_trainingSessions.isEmpty && _enrolledGroupSessions.isEmpty)
          _StatusCard(message: l10n.noSessionsScheduledMessage)
        else ...[
          ..._trainingSessions.map((s) => _sessionCard(s, l10n)),
          ..._enrolledGroupSessions.map((s) => _sessionCard(s, l10n)),
        ],
        if (_availableGroupSessions.isNotEmpty) ...[
          const SizedBox(height: 22),
          StudentSectionTitle(
            title: l10n.availableGroupClassesTitle,
            subtitle: l10n.enrollOpenSlotsSubtitle,
          ),
          const SizedBox(height: 12),
          ..._availableGroupSessions.map(
            (session) => _sessionCard(
              session,
              l10n,
              action: TextButton.icon(
                onPressed: () => _enrollGroupSession(session),
                icon: const Icon(Icons.how_to_reg),
                label: Text(l10n.enrollMeAction),
              ),
            ),
          ),
        ],
      ];
    }

    return [
      StudentMenuScreen(
        studentName: _studentName.isEmpty ? l10n.accountStudent : _studentName,
        profilePictureUrl: _profilePictureUrl,
        isUploadingProfilePicture: _isUploadingProfilePicture,
        onBack: () => setState(() => _selectedNavIndex = 0),
        onLogout: _logout,
        onOpenChat: _openChat,
        onEditPhoto: _pickAndUploadProfilePicture,
        onOpenSection: _openSection,
      ),
    ];
  }

  Widget _homeSummaryCards() {
    final scheduledSessions = [
      ..._trainingSessions,
      ..._enrolledGroupSessions,
    ].where((session) => session.status == 'scheduled').length;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryTile(
          icon: Icons.fitness_center,
          value: _workouts.length.toString(),
          label: 'Treinos',
          onTap: () => _openSection(1),
        ),
        _SummaryTile(
          icon: Icons.event_available_outlined,
          value: scheduledSessions.toString(),
          label: 'Sessões',
          onTap: () => _openSection(8),
        ),
        _SummaryTile(
          icon: Icons.water_drop_outlined,
          value:
              '${((_waterMl / _waterGoalMl) * 100).clamp(0, 100).round()}%',
          label: 'Hidratação',
        ),
        _SummaryTile(
          icon: Icons.trending_up,
          value: 'Ver',
          label: 'Progresso',
          onTap: () => _openSection(5),
        ),
      ],
    );
  }

  Widget _todayHighlightCard() {
    final nextSession = _nextSession();
    final todayWorkout = _plansForDate(DateTime.now()).isNotEmpty
        ? _plansForDate(DateTime.now()).first
        : (_workouts.isNotEmpty ? _workouts.first : null);

    final hasSession = nextSession != null;
    final title = hasSession ? 'Próxima sessão' : 'Treino em destaque';
    final mainText = hasSession
        ? _sessionDateLabel(nextSession.date)
        : todayWorkout?.title ?? 'Sem treino atribuido';
    final subtitle = hasSession
        ? _sessionSubtitle(nextSession)
        : todayWorkout?.focus ??
              'Quando a personal atribuir um treino, aparece aqui.';
    final icon = hasSession
        ? Icons.event_available_outlined
        : Icons.fitness_center_outlined;
    final actionLabel = hasSession ? 'Ver sessões' : 'Ver treinos';
    final targetIndex = hasSession ? 8 : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: StudentTheme.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mainText,
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openSection(targetIndex),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(actionLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: StudentTheme.blue,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  StudentTrainingSession? _nextSession() {
    final now = DateTime.now();
    final sessions = [
      ..._trainingSessions,
      ..._enrolledGroupSessions,
    ].where((session) {
      return session.status == 'scheduled' && session.date.isAfter(now);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return sessions.isEmpty ? null : sessions.first;
  }

  void _openSection(int index) {
    setState(() {
      _selectedNavIndex = index;
      if (index == 6) {
        _isProfileDetailView = false;
        _profileBackRequest++;
      } else {
        _isProfileDetailView = false;
      }
    });
  }

  Widget _workoutCard(StudentWorkoutPlan workout) {
    return StudentWorkoutCard(
      workout: workout,
      isCompleted: _completedWorkoutIds.contains(workout.id),
      onOpen: () => _showWorkoutDetails(workout),
    );
  }

  Widget _sessionCard(
    StudentTrainingSession session,
    AppLocalizations l10n, {
    Widget? action,
  }) {
    return GestureDetector(
      onTap: () => _showSessionDetails(session),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: StudentTheme.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: StudentTheme.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sessionDateLabel(session.date, l10n),
                    style: const TextStyle(
                      color: StudentTheme.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sessionSubtitle(session, l10n),
                    style: const TextStyle(
                      color: StudentTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      session.notes!,
                      style: const TextStyle(
                        color: StudentTheme.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (action != null) ...[const SizedBox(height: 10), action],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chevron_right,
                  color: StudentTheme.mutedText,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.viewAction,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(StudentTrainingSession session) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: StudentTheme.navy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.84,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: StudentTheme.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_available_outlined,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sessionTypeTitle(session, l10n),
                              style: const TextStyle(
                                color: StudentTheme.darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sessionStatusLabel(session.status, l10n),
                              style: TextStyle(
                                color: _sessionStatusColor(session.status),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sessionDetailRow(
                    Icons.calendar_today_outlined,
                    l10n.dateAndTimeLabel,
                    _sessionDateLabel(session.date, l10n),
                  ),
                  _sessionDetailRow(
                    Icons.category_outlined,
                    l10n.typeLabel,
                    session.sessionType == 'group'
                        ? l10n.groupClassLabelShort
                        : l10n.individualSessionLabel,
                  ),
                  if (session.sessionType == 'group')
                    _sessionDetailRow(
                      Icons.groups_outlined,
                      l10n.slotsLabel,
                      l10n.enrolledCountLabel(
                        session.registeredStudents.toString(),
                        session.maxStudents?.toString() ?? '-',
                      ),
                    ),
                  if (session.workoutPlanId != null &&
                      session.workoutPlanId!.isNotEmpty)
                    _sessionDetailRow(
                      Icons.fitness_center_outlined,
                      l10n.associatedPlanLabel,
                      _workoutTitleForSession(session, l10n),
                    ),
                  _sessionDetailRow(
                    Icons.notes_outlined,
                    l10n.trainerNotesLabel,
                    session.notes?.trim().isNotEmpty == true
                        ? session.notes!.trim()
                        : l10n.noNotesForSessionMessage,
                  ),
                  const SizedBox(height: 14),
                  if (session.sessionType == 'group' &&
                      session.isEnrolled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7185),
                          side: const BorderSide(color: Color(0xFFFF7185)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmUnenrollGroupSession(session);
                        },
                        icon: const Icon(Icons.event_busy_outlined),
                        label: Text(l10n.cancelEnrollmentAction),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sessionDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: StudentTheme.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _toggleWorkout(StudentWorkoutPlan workout) {
    setState(() {
      if (_completedWorkoutIds.contains(workout.id)) {
        _completedWorkoutIds.remove(workout.id);
      } else {
        _completedWorkoutIds.add(workout.id);
      }
    });
  }

  void _showWorkoutDetails(StudentWorkoutPlan workout) {
    final isCompleted = _completedWorkoutIds.contains(workout.id);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: StudentTheme.navy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.84,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: workout.color.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(workout.icon, color: workout.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.title,
                              style: const TextStyle(
                                color: StudentTheme.darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCompleted
                                  ? l10n.completedStatusLabel
                                  : l10n.pendingStatusLabel,
                              style: TextStyle(
                                color: isCompleted
                                    ? StudentTheme.blue
                                    : const Color(0xFFFFD36A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sessionDetailRow(
                    Icons.timer_outlined,
                    l10n.estimatedDurationLabel,
                    l10n.durationMinutesValue(workout.durationMinutes.toString()),
                  ),
                  _sessionDetailRow(
                    Icons.fitness_center_outlined,
                    l10n.exercisesLabel,
                    workout.exercises.isEmpty
                        ? l10n.noExercisesDefinedMessage
                        : l10n.exercisesCountLabel(workout.exercises.length.toString()),
                  ),
                  if (workout.exercises.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...workout.exercises.map(
                      (exercise) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          exercise,
                          style: const TextStyle(
                            color: StudentTheme.darkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleWorkout(workout);
                      },
                      icon: Icon(
                        isCompleted
                            ? Icons.replay_outlined
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        isCompleted
                            ? l10n.markAsPendingAction
                            : l10n.markAsCompletedAction,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addWater(int amountMl) {
    if (_waterMl >= _waterGoalMl) return;

    setState(() {
      _waterMl = (_waterMl + amountMl).clamp(0, _waterGoalMl).toInt();
    });
    _saveHydration();

    if (_waterMl == _waterGoalMl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.hydrationGoalCompletedMessage)),
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

    final userData = await ApiService.get(context, '/api/v1/profile/me', token);
    if (!mounted || userData == null) return;

    _applyProfileData(userData);
  }

  Future<void> _pickAndUploadProfilePicture() async {
    final token = widget.token;
    if (token == null || token.isEmpty || _isUploadingProfilePicture) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image == null) return;

    setState(() => _isUploadingProfilePicture = true);

    final result = await ApiService.uploadProfilePicture(context, token, image);

    if (!mounted) return;
    setState(() => _isUploadingProfilePicture = false);

    if (result is Map<String, dynamic> && result['id'] != null) {
      _applyProfileData(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    } else {
      final message = result is Map<String, dynamic> &&
              result['detail'] is String &&
              (result['detail'] as String).isNotEmpty
          ? result['detail'] as String
          : 'Nao foi possivel enviar a foto.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _applyProfileData(Map<String, dynamic> userData) {
    final name = userData['name'];
    final email = userData['email'];
    final profilePictureUrl = userData['profile_picture_url'];

    setState(() {
      if (name is String && name.trim().isNotEmpty) {
        _studentName = name.trim();
      }
      if (email is String) {
        _studentEmail = email.trim();
      }
      _profilePictureUrl =
          profilePictureUrl is String && profilePictureUrl.trim().isNotEmpty
              ? profilePictureUrl.trim()
              : null;
    });
  }

  Future<void> _loadWorkoutPlans() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingWorkouts = false;
        _workoutErrorMessage = AppLocalizations.of(context)!.loginToAccessWorkoutsMessage;
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

      final l10n = AppLocalizations.of(context)!;
      setState(() {
        if (data is List) {
          _workouts = List.generate(
            data.length,
            (index) => _workoutFromApi(data[index], index, l10n),
          );
        }
        _isLoadingWorkouts = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _workoutErrorMessage = AppLocalizations.of(context)!.workoutsLoadError;
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

  Future<void> _loadEnrolledGroupSessions() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/group_sessions/',
        token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted || data is! List) return;

      setState(() {
        _enrolledGroupSessions = data
            .map(_groupSessionFromApi)
            .whereType<StudentTrainingSession>()
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _loadAvailableGroupSessions() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/group_sessions/available',
        token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted || data is! List) return;

      setState(() {
        _availableGroupSessions = data
            .map(_groupSessionFromApi)
            .whereType<StudentTrainingSession>()
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _enrollGroupSession(StudentTrainingSession session) async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    final data = await ApiService.post(
      context,
      '/api/v1/group_sessions/${session.id}/enroll',
      token,
      {},
    );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (data is Map && data['id'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enrollmentSuccessMessage)),
      );
      _loadEnrolledGroupSessions();
      _loadAvailableGroupSessions();
    } else {
      final detail = data is Map ? data['detail']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(detail ?? l10n.enrollmentError),
        ),
      );
    }
  }

  StudentWorkoutPlan _workoutFromApi(dynamic value, int index, AppLocalizations l10n) {
    final plan = value is Map<String, dynamic> ? value : <String, dynamic>{};
    final exercisesData = plan['exercises'] is List
        ? plan['exercises'] as List
        : const [];
    final exercises = exercisesData.whereType<Map<String, dynamic>>().map((
      exercise,
    ) {
      final name = _text(exercise['name'], l10n.exerciseFallback);
      final sets = exercise['sets'];
      final reps = exercise['reps'];

      if (sets == null || reps == null) return name;
      return '$name ${sets}x$reps';
    }).toList();

    return StudentWorkoutPlan(
      id: _text(plan['id'], 'workout-$index'),
      title: _text(plan['title'], l10n.workoutFallbackTitle((index + 1).toString())),
      focus: exercises.isEmpty
          ? l10n.planAssignedLabel
          : l10n.exercisesCountShort(exercises.length.toString()),
      weekday: (index % 7) + 1,
      scheduledDate: _sessionDateForWorkout(
        _text(plan['id'], 'workout-$index'),
      ),
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
      notes: session['notes']?.toString(),
    );
  }

  StudentTrainingSession? _groupSessionFromApi(dynamic value) {
    final session = value is Map<String, dynamic> ? value : null;
    if (session == null) return null;

    final rawDate = session['date'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (date == null) return null;

    return StudentTrainingSession(
      id: _text(session['id'], 'group-session'),
      workoutPlanId: null,
      date: date,
      status: _text(session['status'], 'scheduled'),
      sessionType: 'group',
      maxStudents: _intOrNull(session['max_students']),
      registeredStudents: _intOrNull(session['registered_students']) ?? 0,
      isEnrolled: session['is_enrolled'] == true,
      notes: session['notes']?.toString(),
    );
  }

  static String _sessionDateLabel(DateTime date, AppLocalizations l10n) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return l10n.dateTimeAt('$day/$month/$year', '$hour:$minute');
  }

  static String _sessionStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'scheduled':
        return l10n.sessionStatusScheduled;
      case 'completed':
        return l10n.sessionStatusCompleted;
      case 'cancelled':
        return l10n.sessionStatusCancelled;
      default:
        return status;
    }
  }

  static Color _sessionStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return StudentTheme.blue;
      case 'completed':
        return const Color(0xFF63D471);
      case 'cancelled':
        return const Color(0xFFFF7185);
      default:
        return StudentTheme.mutedText;
    }
  }

  static String _sessionSubtitle(StudentTrainingSession session, AppLocalizations l10n) {
    final status = _sessionStatusLabel(session.status, l10n);
    if (session.sessionType != 'group') return status;

    final maxStudents = session.maxStudents?.toString() ?? '-';
    return l10n.groupClassSubtitle(
      session.registeredStudents.toString(),
      maxStudents,
      status,
    );
  }

  static String _sessionTypeTitle(StudentTrainingSession session, AppLocalizations l10n) {
    return session.sessionType == 'group'
        ? l10n.groupClassDetailsTitle
        : l10n.sessionDetailsTitle;
  }

  String _workoutTitleForSession(StudentTrainingSession session, AppLocalizations l10n) {
    final workoutPlanId = session.workoutPlanId;
    if (workoutPlanId == null || workoutPlanId.isEmpty) {
      return l10n.noAssociatedPlanMessage;
    }

    for (final workout in _workouts) {
      if (workout.id == workoutPlanId) return workout.title;
    }

    return l10n.planNumberLabel(workoutPlanId);
  }

  Future<void> _confirmUnenrollGroupSession(
    StudentTrainingSession session,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelEnrollmentTitle),
        content: Text(
          l10n.confirmCancelEnrollmentMessage(_sessionDateLabel(session.date, l10n)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.backAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelEnrollmentAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _unenrollGroupSession(session);
    }
  }

  Future<void> _unenrollGroupSession(StudentTrainingSession session) async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    final data = await ApiService.delete(
      context,
      '/api/v1/group_sessions/${session.id}/enroll',
      token,
    );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (data is Map && data['message'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enrollmentCancelledMessage)),
      );
      _loadEnrolledGroupSessions();
      _loadAvailableGroupSessions();
    } else {
      final detail = data is Map ? data['detail']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(detail ?? l10n.enrollmentCancelError),
        ),
      );
    }
  }

  void _openChat() {
    final token = widget.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginToAccessChatMessage)),
      );
      return;
    }

    setState(() => _isChatOpen = true);
  }

  Widget _floatingChat() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final isCompact = screenWidth < 700;
    final isDesktop = screenWidth >= 1100;
    final sideMargin = isCompact ? 12.0 : 24.0;
    final bottomMargin = isCompact ? 92.0 : 96.0;
    final availableWidth = screenWidth - (sideMargin * 2);
    final availableHeight =
        screenHeight - media.padding.top - bottomMargin - 24;
    final maxChatWidth = isDesktop ? 520.0 : 680.0;
    final minChatWidth = isCompact ? 300.0 : 420.0;
    final targetChatWidth = isCompact
        ? availableWidth
        : isDesktop
            ? 520.0
            : screenWidth * 0.72;
    final maxChatHeight = isDesktop ? 560.0 : 640.0;
    final minChatHeight = isCompact ? 320.0 : 460.0;
    final targetChatHeight = isCompact
        ? 360.0
        : isDesktop
            ? 520.0
            : screenHeight * 0.68;
    final chatWidth = _boundedDouble(
      targetChatWidth,
      minChatWidth,
      availableWidth < maxChatWidth ? availableWidth : maxChatWidth,
    );
    final chatHeight = _boundedDouble(
      targetChatHeight,
      minChatHeight,
      availableHeight < maxChatHeight ? availableHeight : maxChatHeight,
    );

    return Positioned(
      right: sideMargin,
      bottom: bottomMargin,
      child: SizedBox(
        width: chatWidth,
        height: chatHeight,
        child: StudentFloatingChat(
          token: widget.token!,
          onClose: () => setState(() => _isChatOpen = false),
        ),
      ),
    );
  }

  static double _boundedDouble(double value, double lower, double upper) {
    if (upper < lower) return upper;
    if (value < lower) return lower;
    if (value > upper) return upper;
    return value;
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

  static int? _intOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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
        style: const TextStyle(color: StudentTheme.mutedText, fontSize: 14),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StudentTheme.navy,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: StudentTheme.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentTheme.darkText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentTheme.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
