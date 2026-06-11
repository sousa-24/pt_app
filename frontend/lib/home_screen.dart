import 'package:flutter/material.dart';
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
