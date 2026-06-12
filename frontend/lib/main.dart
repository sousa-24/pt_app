import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'screens/student/student_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FITPRO App',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0FD3E),
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0FD3E),
          primary: const Color(0xFFD0FD3E),
          onPrimary: Colors.black,
          surface: const Color(0xFF2C2C2E),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),

      themeMode: _themeMode,
      home: LoginScreen(onToggleTheme: toggleTheme, themeMode: _themeMode),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const LoginScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _showPassword = false;
  String _selectedAccount = 'client';
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF4F4F1);
    final textColor = isDark
        ? const Color(0xFFF4F4F1)
        : const Color(0xFF1C1C1E);
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 18.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const SizedBox(height: 36),

                Icon(Icons.fitness_center, size: 74, color: primaryColor),

                const SizedBox(height: 14),

                Text(
                  'FITPRO',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                Text(
                  'O seu app',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 42),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Entrar como',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      _AccountOptionButton(
                        label: 'Aluno',
                        icon: Icons.school_outlined,
                        isSelected: _selectedAccount == 'client',
                        onTap: () =>
                            setState(() => _selectedAccount = 'client'),
                      ),
                      _AccountOptionButton(
                        label: 'Personal',
                        icon: Icons.fitness_center,
                        isSelected: _selectedAccount == 'trainer',
                        onTap: () =>
                            setState(() => _selectedAccount = 'trainer'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) login();
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _showPassword ? 'Esconder senha' : 'Ver senha',
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,

                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),

                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton(
                    onPressed: () {
                      _openRegisterScreen();
                    },

                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withOpacity(0.65)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      'Criar nova conta',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRegisterScreen() async {
    final registeredRole = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          onToggleTheme: widget.onToggleTheme,
          themeMode: widget.themeMode,
        ),
      ),
    );

    if (!mounted || registeredRole == null) return;

    setState(() {
      emailController.clear();
      passwordController.clear();
      errorMessage = '';
      _showPassword = false;
      _selectedAccount = registeredRole;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta criada! Faca login para entrar.')),
    );
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        AppConfig.apiUri('/api/v1/login/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['access_token'];
        final role = data['role'];

        if (!mounted) return;

        if (role != _selectedAccount) {
          setState(() {
            errorMessage = _selectedAccount == 'client'
                ? 'Esta conta nao e de aluno'
                : 'Esta conta nao e de personal';
          });
          return;
        }

        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder: (context) => role == 'client'
                ? StudentHomeScreen(
                    token: token,
                    role: role,
                    onToggleTheme: widget.onToggleTheme,
                    themeMode: widget.themeMode,
                  )
                : HomeScreen(
                    token: token,
                    role: role,
                    onToggleTheme: widget.onToggleTheme,
                    themeMode: widget.themeMode,
                  ),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Could not connect to server';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class _AccountOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.black : inactiveColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : inactiveColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
