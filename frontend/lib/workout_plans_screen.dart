import 'package:flutter/material.dart';
import 'api_service.dart';
import 'create_workout_plan_screen.dart';
import 'l10n/gen/app_localizations.dart';

class WorkoutPlansScreen extends StatefulWidget {
  final String token;
  final String role;

  const WorkoutPlansScreen({
    super.key,
    required this.token,
    this.role = 'client',
  });

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

  bool get isTrainer => widget.role == 'trainer';

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
          errorMessage = AppLocalizations.of(context)!.workoutPlansLoadError;
        }
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(context)!.serverContactError;
        isLoading = false;
      });
    }
  }

  Future<void> editPlan(Map<String, dynamic> plan) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateWorkoutPlanScreen(token: widget.token, existingPlan: plan),
      ),
    );

    if (updated == true) {
      fetchPlans();
    }
  }

  Future<void> deletePlan(Map<String, dynamic> plan) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlanTitle),
        content: Text(
          l10n.confirmDeletePlanMessage(plan['title'] ?? l10n.thisPlanFallback),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final data = await ApiService.delete(
      context,
      '/api/v1/workout_plans/${plan['id']}',
      widget.token,
    );
    if (!mounted) return;

    if (data is Map && data['message'] != null) {
      fetchPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workoutPlanDeletedMessage)),
      );
    } else {
      setState(() => errorMessage = l10n.mealPlanDeleteError);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.myWorkoutsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          ? Center(
              child: Text(
                l10n.noWorkoutPlansAssignedMessage,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: plans.length,
              itemBuilder: (context, planIndex) {
                final plan = plans[planIndex];
                final planMap = plan is Map<String, dynamic>
                    ? plan
                    : <String, dynamic>{};
                final exercises = planMap['exercises'] is List
                    ? planMap['exercises'] as List
                    : const [];

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: accentColor,
                      collapsedIconColor: Colors.white,
                      title: Text(
                        planMap['title'] ?? l10n.workoutPlanFallback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        l10n.createdOnLabel(
                          planMap['created_at'] ?? l10n.recentlyLabel,
                        ),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      trailing: isTrainer
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.editPlanTooltip,
                                  icon: const Icon(Icons.edit_outlined),
                                  color: accentColor,
                                  onPressed: () => editPlan(planMap),
                                ),
                                IconButton(
                                  tooltip: l10n.deletePlanTooltip,
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.redAccent,
                                  onPressed: () => deletePlan(planMap),
                                ),
                              ],
                            )
                          : null,
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
                                color: isCompleted
                                    ? accentColor
                                    : Colors.white60,
                              ),
                              title: Text(
                                exerciseMap['name'] ?? l10n.exerciseFallback,
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
                                l10n.setsRepsLabel(
                                  exerciseMap['sets'].toString(),
                                  exerciseMap['reps'].toString(),
                                ),
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
