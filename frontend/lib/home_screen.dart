import 'package:flutter/material.dart';
import 'workout_plans_screen.dart';
import 'chat_screen.dart'; // Import do teu chat já incluído!
import 'progression_screen.dart';
import 'main.dart';
import 'create_workout_plan_screen.dart';
import 'schedule_session_screen.dart';
import 'sessions_screen.dart';
import 'invite_code_screen.dart';
import 'nutri_plans_screen.dart';
import 'create_nutri_plans_screen.dart';

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
                role == 'trainer' ? 'Trainer Menu' : 'Client Menu',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            
            // MENU DO TREINADOR (TRAINER)
            if (role == 'trainer') ...[
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('View Workout Plans'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutPlansScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Create Workout Plan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateWorkoutPlanScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Sessions'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Schedule Session'),
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
                title: const Text('Generate Invite Code'),
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
                title: const Text('View Nutrition Plans'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NutriPlansScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Create Nutrition Plan'),
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
              // O TEU CHAT ADICIONADO PARA O PT:
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFFD0FD3E)),
                title: const Text('Chat com Alunos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(token: token, role: role),
                    ),
                  );
                },
              ),
              
            // MENU DO ALUNO (CLIENT)
            ] else ...[
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Workout Plans'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutPlansScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Progression'),
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
                title: const Text('My Sessions'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionsScreen(token: token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Nutrition Plans'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NutriPlansScreen(token: token),
                    ),
                  );
                },
              ),
              // O TEU CHAT ADICIONADO PARA O CLIENTE:
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFFD0FD3E)),
                title: const Text('Chat com o PT'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(token: token, role: role),
                    ),
                  );
                },
              ),
            ],
            
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role == 'trainer' ? 'Welcome, Trainer!' : 'Welcome!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Use the menu on the top left to navigate.'),
          ],
        ),
      ),
    );
  }
}