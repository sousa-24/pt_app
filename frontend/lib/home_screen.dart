import 'package:fl_chart/fl_chart.dart';
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

  // Função que chama a API do teu colega para buscar o progresso do aluno 1 (CassiaM)
  Future<List<dynamic>> _fetchProgressionData(BuildContext context) async {
    final response = await ApiService.get(
      context,
      '/api/v1/progression/1',
      token,
    );
    if (response is List) {
      return response;
    } else if (response is Map && response.containsKey('data')) {
      return response['data'] as List<dynamic>;
    }
    return [];
  }

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
                      builder: (context) => WorkoutPlansScreen(token: token),
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
                      builder: (context) => NutriPlansScreen(token: token),
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
                      builder: (context) => WorkoutPlansScreen(token: token),
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
                      builder: (context) => NutriPlansScreen(token: token),
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

              // === DASHBOARD DO TREINADOR EM PORTUGUÊS ===
              if (role == 'trainer') ...[
                const Text(
                  'Visão Geral do Progresso (CassiaM)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 340,
                  child: FutureBuilder<List<dynamic>>(
                    future: _fetchProgressionData(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFD0FD3E),
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            //'Erro ao carregar os dados de progresso.',
                            "Erro real: ${snapshot.error}",
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final List<Map<String, dynamic>> progressionList =
                          (snapshot.data ?? [])
                              .map(
                                (item) =>
                                    Map<String, dynamic>.from(item as Map),
                              )
                              .toList();

                      return TrainerProgressOverviewChart(
                        progressionData: progressionList,
                      );
                    },
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

class TrainerProgressOverviewChart extends StatelessWidget {
  final List<Map<String, dynamic>> progressionData;

  const TrainerProgressOverviewChart({
    super.key,
    required this.progressionData,
  });

  @override
  Widget build(BuildContext context) {
    final chartSeries = _buildChartSeries();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Peso', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 18),
              const _LegendDot(color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Massa muscular',
                style: TextStyle(color: Colors.white70),
              ),
              if (progressionData.isEmpty) ...[
                const Spacer(),
                const Text(
                  'Amostra visual',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 25,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final index = value.round();
                        if (index < 0 || index >= chartSeries.labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            chartSeries.labels[index],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2C2C2E),
                  ),
                ),
                lineBarsData: [
                  _lineData(
                    chartSeries.primary,
                    Theme.of(context).colorScheme.primary,
                    3,
                  ),
                  _lineData(chartSeries.secondary, Colors.white70, 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TrainerChartSeries _buildChartSeries() {
    final usableData = progressionData
        .where((entry) => _readNumber(entry['weight']) > 0)
        .toList();

    if (usableData.length < 2) {
      return const _TrainerChartSeries(
        primary: [32, 39, 45, 52, 57, 63, 67, 72, 78, 82],
        secondary: [18, 25, 31, 38, 42, 49, 55, 58, 63, 68],
        labels: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
      );
    }

    final limitedData = usableData.length > 10
        ? usableData.sublist(usableData.length - 10)
        : usableData;

    final weights = limitedData
        .map((entry) => _readNumber(entry['weight']))
        .toList();
    final muscleMass = limitedData
        .map((entry) => _readNumber(entry['muscle_mass']))
        .toList();

    return _TrainerChartSeries(
      primary: _normalize(weights, minOutput: 30, maxOutput: 88),
      secondary: muscleMass.any((value) => value > 0)
          ? _normalize(muscleMass, minOutput: 18, maxOutput: 68)
          : _normalize(weights, minOutput: 18, maxOutput: 68),
      labels: limitedData
          .map((entry) => _shortDateLabel(entry['date']))
          .toList(),
    );
  }

  static LineChartBarData _lineData(
    List<double> values,
    Color color,
    double width,
  ) {
    return LineChartBarData(
      spots: values
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList(),
      isCurved: true,
      curveSmoothness: 0.32,
      color: color,
      barWidth: width,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  static double _readNumber(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<double> _normalize(
    List<double> values, {
    required double minOutput,
    required double maxOutput,
  }) {
    final validValues = values.where((value) => value > 0).toList();
    if (validValues.isEmpty) {
      return List.filled(values.length, minOutput);
    }

    final minValue = validValues.reduce((a, b) => a < b ? a : b);
    final maxValue = validValues.reduce((a, b) => a > b ? a : b);

    if (maxValue == minValue) {
      return List.filled(values.length, (minOutput + maxOutput) / 2);
    }

    return values.map((value) {
      if (value <= 0) return minOutput;
      return minOutput +
          ((value - minValue) / (maxValue - minValue)) *
              (maxOutput - minOutput);
    }).toList();
  }

  static String _shortDateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 10) {
      return text.substring(5, 10).replaceFirst('-', '/');
    }
    return text;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TrainerChartSeries {
  final List<double> primary;
  final List<double> secondary;
  final List<String> labels;

  const _TrainerChartSeries({
    required this.primary,
    required this.secondary,
    required this.labels,
  });
}
