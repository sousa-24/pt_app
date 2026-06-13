import 'package:flutter/material.dart';
import 'api_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PT App'),
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
                role == 'trainer' ? 'Menu do Treinador' : 'Menu do Aluno',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            // MENU DO TREINADOR (TRAINER)
            if (role == 'trainer') ...[
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Ver Planos de Treino'),
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
                title: const Text('Criar Plano de Treino'),
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
                title: const Text('Sessões Agendadas'),
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
                title: const Text('Agendar Sessão'),
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
                title: const Text('Gerar Código de Convite'),
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
                title: const Text('Ver Planos Nutricionais'),
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
                title: const Text('Feed & Desafios'),
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
                title: const Text('Progresso dos Alunos'),
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
                title: const Text('Faturas'),
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
                title: const Text('Avaliações'),
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
                title: const Text('Criar Plano Nutricional'),
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
                title: const Text('Chat com Alunos'),
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
                title: const Text('Planos de Treino'),
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
                title: const Text('O Meu Progresso'),
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
                title: const Text('As Minhas Sessões'),
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
                title: const Text('Planos Alimentares'),
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
                title: const Text('Chat com o PT'),
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
              leading: const Icon(Icons.logout),
              title: const Text('Sair da Conta'),
              onTap: () {
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
                role == 'trainer' ? 'Bem-vindo, Treinador!' : 'Bem-vindo!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Utiliza o menu no canto superior esquerdo para navegar.',
              ),
              const SizedBox(height: 24),

              if (role == 'trainer') ...[
                const Text(
                  'Área do Personal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _TrainerDashboard(token: token),
                const SizedBox(height: 20),
                const Text(
                  'Acoes rapidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _TrainerShortcutCard(
                  icon: Icons.trending_up,
                  title: 'Progresso dos Alunos',
                  subtitle: 'Escolhe um aluno, vê o gráfico e regista medidas.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerProgressScreen(token: token),
                    ),
                  ),
                ),
                _TrainerShortcutCard(
                  icon: Icons.receipt_long,
                  title: 'Faturas',
                  subtitle: 'Cria faturas e consulta pagamentos registados.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerPaymentsScreen(token: token),
                    ),
                  ),
                ),
                _TrainerShortcutCard(
                  icon: Icons.assignment_outlined,
                  title: 'Avaliações',
                  subtitle: 'Avalia a performance dos alunos nas sessões.',
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
                  label: const Text('Abrir área do aluno'),
                ),
              ),
              if (role == 'trainer') ...[
                const SizedBox(height: 8),
                const Text(
                  'Disponível apenas para utilizadores do tipo aluno (client).',
                  style: TextStyle(color: Colors.grey),
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
  String _nextSession = 'Sem sessoes marcadas';
  String _latestProgress = 'Sem registos recentes';

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
            ? 'Sem sessoes marcadas'
            : _formatDate(upcoming.first['date']);
        _latestProgress = progression.isEmpty
            ? 'Sem registos recentes'
            : _formatDate(progression.first['date']);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel carregar o resumo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(_error!),
          trailing: IconButton(
            tooltip: 'Atualizar',
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
            title: 'Alunos ativos',
            value: _activeClients.toString(),
            detail: 'Ligados a esta conta',
          ),
          _DashboardStatCard(
            icon: Icons.event_available_outlined,
            title: 'Proximas sessoes',
            value: _upcomingSessions.toString(),
            detail: _nextSession,
          ),
          _DashboardStatCard(
            icon: Icons.receipt_long_outlined,
            title: 'Faturas pendentes',
            value: _pendingInvoices.toString(),
            detail: _formatMoney(_pendingAmount),
          ),
          _DashboardStatCard(
            icon: Icons.trending_up,
            title: 'Ultimo progresso',
            value: _latestProgress,
            detail: 'Registo mais recente',
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

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return 'Sem data';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} as $hour:$minute';
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
