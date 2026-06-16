import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'l10n/gen/app_localizations.dart';
import 'workout_plans_screen.dart';
import 'chat_screen.dart';
import 'feed_screen.dart';
import 'progression_screen.dart';
import 'main.dart';
import 'create_workout_plan_screen.dart';
import 'schedule_session_screen.dart';
import 'sessions_screen.dart';
import 'invite_code_screen.dart';
import 'nutri_plans_screen.dart';
import 'create_nutri_plans_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'trainer_evaluations_screen.dart';
import 'trainer_payments_screen.dart';
import 'trainer_progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final String token;
  final String role;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.token,
    required this.role,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeAppBarTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                role == 'trainer' ? l10n.trainerMenuTitle : l10n.studentMenuTitle,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            // MENU DO TREINADOR (TRAINER)
            if (role == 'trainer') ...[
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.viewWorkoutPlansMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkoutPlansScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: Text(l10n.createWorkoutPlanMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateWorkoutPlanScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.scheduledSessionsMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionsScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.scheduleSessionMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScheduleSessionScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: Text(l10n.generateInviteCodeMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InviteCodeScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(l10n.viewNutriPlansMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NutriPlansScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Color(0xFFD0FD3E)),
                title: Text(l10n.feedChallengesMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: Text(l10n.studentsProgressMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerProgressScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(l10n.invoicesTitle),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerPaymentsScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(l10n.evaluationsMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrainerEvaluationsScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: Text(l10n.createNutriPlanMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateNutriPlanScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFFD0FD3E)),
                title: Text(l10n.chatWithStudentsMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(token: token, role: role),
                    ),
                  );
                },
              ),
            ] else ...[
              // MENU DO ALUNO (CLIENT)
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.workoutPlansMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkoutPlansScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: Text(l10n.myProgressMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgressionScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.mySessionsTitle),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionsScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(l10n.mealPlansMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NutriPlansScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFFD0FD3E)),
                title: Text(l10n.chatWithTrainerMenu),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(token: token, role: role),
                    ),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(l10n.myProfileMenu),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logoutMenu),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                await prefs.remove('auth_role');
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      onToggleTheme: onToggleTheme,
                      themeMode: themeMode,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == 'trainer' ? l10n.welcomeTrainerMessage : l10n.welcomeMessage,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.useMenuHint),
              const SizedBox(height: 24),

              if (role == 'trainer') ...[
                Text(
                  l10n.trainerAreaTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _TrainerDashboard(token: token),
                const SizedBox(height: 20),
                Text(
                  l10n.quickActionsTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _TrainerShortcutCard(
                  icon: Icons.trending_up,
                  title: l10n.studentsProgressMenu,
                  subtitle: l10n.progressShortcutSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerProgressScreen(token: token),
                    ),
                  ),
                ),
                _TrainerShortcutCard(
                  icon: Icons.receipt_long,
                  title: l10n.invoicesTitle,
                  subtitle: l10n.invoicesShortcutSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerPaymentsScreen(token: token),
                    ),
                  ),
                ),
                _TrainerShortcutCard(
                  icon: Icons.assignment_outlined,
                  title: l10n.evaluationsMenu,
                  subtitle: l10n.evaluationsShortcutSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrainerEvaluationsScreen(token: token),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ==================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: role == 'client'
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentHomeScreen(
                                token: token,
                                role: role,
                                onToggleTheme: onToggleTheme,
                                themeMode: themeMode,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.school_outlined),
                  label: Text(l10n.openStudentAreaButton),
                ),
              ),
              if (role == 'trainer') ...[
                const SizedBox(height: 8),
                Text(
                  l10n.onlyForClientUsersMessage,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerDashboard extends StatefulWidget {
  final String token;

  const _TrainerDashboard({required this.token});

  @override
  State<_TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<_TrainerDashboard> {
  bool _isLoading = true;
  String? _error;
  int _activeClients = 0;
  int _upcomingSessions = 0;
  int _pendingInvoices = 0;
  double _pendingAmount = 0;
  String _nextSession = '';
  String _latestProgress = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get(context, '/api/v1/my-contacts/', widget.token),
        ApiService.get(context, '/api/v1/training_sessions/', widget.token),
        ApiService.get(context, '/api/v1/group_sessions/', widget.token),
        ApiService.get(context, '/api/v1/payments/', widget.token),
        ApiService.get(context, '/api/v1/progression/', widget.token),
      ]);
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final contacts = _asMaps(results[0]);
      final sessions = [..._asMaps(results[1]), ..._asMaps(results[2])];
      final payments = _asMaps(results[3]);
      final progression = _asMaps(results[4]);
      final now = DateTime.now();
      final upcoming =
          sessions.where((session) {
            final date = DateTime.tryParse(session['date']?.toString() ?? '');
            final status = session['status']?.toString() ?? 'scheduled';
            return date != null && date.isAfter(now) && status == 'scheduled';
          }).toList()..sort((a, b) {
            final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
            final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });

      final pending = payments.where((payment) {
        final status = payment['status']?.toString();
        return status == 'pending' || status == 'overdue';
      }).toList();

      progression.sort((a, b) {
        final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _activeClients = contacts.length;
        _upcomingSessions = upcoming.length;
        _pendingInvoices = pending.length;
        _pendingAmount = pending.fold<double>(0, (sum, payment) {
          final value = payment['cost'];
          final amount = value is num
              ? value.toDouble()
              : double.tryParse(value?.toString() ?? '') ?? 0;
          return sum + amount;
        });
        _nextSession = upcoming.isEmpty
            ? l10n.noSessionsScheduledLabel
            : _formatDate(upcoming.first['date'], l10n);
        _latestProgress = progression.isEmpty
            ? l10n.noRecentRecordsLabel
            : _formatDate(progression.first['date'], l10n);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.summaryLoadError;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(_error!),
          trailing: IconButton(
            tooltip: l10n.refreshTooltip,
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final cards = [
          _DashboardStatCard(
            icon: Icons.people_outline,
            title: l10n.activeStudentsLabel,
            value: _activeClients.toString(),
            detail: l10n.linkedToAccountLabel,
          ),
          _DashboardStatCard(
            icon: Icons.event_available_outlined,
            title: l10n.upcomingSessionsLabel,
            value: _upcomingSessions.toString(),
            detail: _nextSession,
          ),
          _DashboardStatCard(
            icon: Icons.receipt_long_outlined,
            title: l10n.pendingInvoicesLabel,
            value: _pendingInvoices.toString(),
            detail: _formatMoney(_pendingAmount),
          ),
          _DashboardStatCard(
            icon: Icons.trending_up,
            title: l10n.lastProgressLabel,
            value: _latestProgress,
            detail: l10n.mostRecentRecordLabel,
          ),
        ];

        if (!wide) {
          return Column(children: cards);
        }

        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 3.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

List<Map<String, dynamic>> _asMaps(dynamic value) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _formatDate(dynamic value, AppLocalizations l10n) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return l10n.noDate;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return l10n.dateTimeAt('$day/$month/${parsed.year}', '$hour:$minute');
}

String _formatMoney(num value) {
  return 'EUR ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  const _DashboardStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(detail),
        trailing: SizedBox(
          width: 120,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _TrainerShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TrainerShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
