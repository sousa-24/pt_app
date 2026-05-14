import 'package:flutter/material.dart';
import 'workout_plans_screen.dart';
import 'progression_screen.dart';
import 'main.dart';

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
          icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
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
          if (role == 'trainer') ...[
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Workout Plans'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => WorkoutPlansScreen(token: token),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Sessions'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Workout Plans'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => WorkoutPlansScreen(token: token),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Progression'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ProgressionScreen(token: token),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Sessions'),
              onTap: () {
                Navigator.pop(context);
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
