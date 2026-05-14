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

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final data = await ApiService.get(context, '/workout_plans/', widget.token);
    if (data != null) {
      setState(() {
        plans = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Plans')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
          ? const Center(child: Text('No workout plans yet'))
          : ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return ExpansionTile(
                  title: Text(plan['title']),
                  subtitle: Text('Created: ${plan['created_at']}'),
                  children: [
                    ...plan['exercises'].map<Widget>((exercise) {
                      return ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(exercise['name']),
                        subtitle: Text(
                          '${exercise['sets']} sets x ${exercise['reps']} reps',
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }
}
