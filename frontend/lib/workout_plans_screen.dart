import 'package:flutter/material.dart';
import 'api_service.dart';

class WorkoutPlansScreen extends StatefulWidget {
  final String token;

  const WorkoutPlansScreen({super.key, required this.token});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  List plans = [];
  bool isLoading = true;
  String errorMessage = '';

  final Color backgroundColor = const Color(0xFF1C1C1E);
  final Color cardColor = const Color(0xFF2C2C2E);
  final Color accentColor = const Color(0xFFD0FD3E);

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      final data = await ApiService.get(
        context,
        '/api/v1/workout_plans/',
        widget.token,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      setState(() {
        if (data is List) {
          plans = data.map((plan) {
            if (plan is Map<String, dynamic> && plan['exercises'] is List) {
              plan['exercises'] = (plan['exercises'] as List).map((exercise) {
                if (exercise is Map<String, dynamic>) {
                  exercise['is_completed'] = exercise['is_completed'] ?? false;
                }
                return exercise;
              }).toList();
            }
            return plan;
          }).toList();
          errorMessage = '';
        } else {
          errorMessage = 'Nao foi possivel carregar os planos de treino.';
        }
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Nao foi possivel contactar o servidor.';
        isLoading = false;
      });
    }
  }

  Future<void> toggleExerciseStatus(
    int planIndex,
    int exerciseIndex,
    bool? newValue,
  ) async {
    setState(() {
      plans[planIndex]['exercises'][exerciseIndex]['is_completed'] = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Os Meus Treinos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : plans.isEmpty
                  ? const Center(
                      child: Text(
                        'Ainda nao tens planos de treino atribuidos.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: plans.length,
                      itemBuilder: (context, planIndex) {
                        final plan = plans[planIndex];
                        final exercises = plan is Map<String, dynamic> &&
                                plan['exercises'] is List
                            ? plan['exercises'] as List
                            : const [];

                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              iconColor: accentColor,
                              collapsedIconColor: Colors.white,
                              title: Text(
                                plan is Map<String, dynamic>
                                    ? plan['title'] ?? 'Plano de Treino'
                                    : 'Plano de Treino',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                'Criado em: ${plan is Map<String, dynamic> ? plan['created_at'] ?? 'recentemente' : 'recentemente'}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                              children: [
                                const Divider(color: Colors.black26, height: 1),
                                ...List.generate(exercises.length, (exerciseIndex) {
                                  final exercise = exercises[exerciseIndex];
                                  final exerciseMap = exercise is Map<String, dynamic>
                                      ? exercise
                                      : <String, dynamic>{};
                                  final bool isCompleted =
                                      exerciseMap['is_completed'] == true;

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: backgroundColor.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.fitness_center,
                                        color:
                                            isCompleted ? accentColor : Colors.white60,
                                      ),
                                      title: Text(
                                        exerciseMap['name'] ?? 'Exercicio',
                                        style: TextStyle(
                                          color: isCompleted
                                              ? Colors.white54
                                              : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${exerciseMap['sets']} series x ${exerciseMap['reps']} repeticoes',
                                        style: TextStyle(
                                          color: isCompleted
                                              ? Colors.white38
                                              : Colors.white70,
                                        ),
                                      ),
                                      trailing: Checkbox(
                                        activeColor: accentColor,
                                        checkColor: Colors.black,
                                        side: const BorderSide(
                                          color: Colors.white60,
                                          width: 2,
                                        ),
                                        value: isCompleted,
                                        onChanged: (bool? value) {
                                          toggleExerciseStatus(
                                            planIndex,
                                            exerciseIndex,
                                            value,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
