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

  // Definição de cores do FITPRO
  final Color backgroundColor = const Color(0xFF1C1C1E);
  final Color cardColor = const Color(0xFF2C2C2E);
  final Color accentColor = const Color(0xFFD0FD3E); // Verde Neon

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final data = await ApiService.get(context, '/workout_plans/', widget.token);
    if (data != null) {
      setState(() {
        // Mapeamos os planos e adicionamos um estado local 'completed' para os exercícios
        plans = data.map((plan) {
          if (plan['exercises'] != null) {
            plan['exercises'] = plan['exercises'].map((exercise) {
              // Se o backend ainda não guardar o estado, começamos com false
              exercise['is_completed'] = exercise['is_completed'] ?? false;
              return exercise;
            }).toList();
          }
          return plan;
        }).toList();
        isLoading = false;
      });
    }
  }

  // Função simulada para avisar o backend (o teu colega depois cria a rota)
  Future<void> toggleExerciseStatus(int planIndex, int exerciseIndex, bool? newValue) async {
    setState(() {
      plans[planIndex]['exercises'][exerciseIndex]['is_completed'] = newValue;
    });

    // Opcional: Enviar para a API o progresso real
    // await ApiService.post(context, '/workout_plans/toggle_exercise', ...);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Os Meus Treinos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : plans.isEmpty
              ? const Center(child: Text('Ainda não tens planos de treino atribuídos.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: plans.length,
                  itemBuilder: (context, planIndex) {
                    final plan = plans[planIndex];
                    
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: accentColor,
                          collapsedIconColor: Colors.white,
                          title: Text(
                            plan['title'] ?? 'Plano de Treino',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            'Criado em: ${plan['created_at'] ?? 'Recentemente'}',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          children: [
                            const Divider(color: Colors.black26, height: 1),
                            ...List.generate(plan['exercises']?.length ?? 0, (exerciseIndex) {
                              final exercise = plan['exercises'][exerciseIndex];
                              final bool isCompleted = exercise['is_completed'] == true;

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: backgroundColor.withOpacity(0.5), width: 1)),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.fitness_center,
                                    color: isCompleted ? accentColor : Colors.white60,
                                  ),
                                  title: Text(
                                    exercise['name'] ?? 'Exercício',
                                    style: TextStyle(
                                      color: isCompleted ? Colors.white54 : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null, // Efeito visual de rasurado
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${exercise['sets']} séries x ${exercise['reps']} reps',
                                    style: TextStyle(color: isCompleted ? Colors.white38 : Colors.white70),
                                  ),
                                  trailing: Checkbox(
                                    activeColor: accentColor,
                                    checkColor: Colors.black,
                                    side: const BorderSide(color: Colors.white60, width: 2),
                                    value: isCompleted,
                                    onChanged: (bool? value) {
                                      toggleExerciseStatus(planIndex, exerciseIndex, value);
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