import 'package:flutter/material.dart';
import 'api_service.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final String token;

  const CreateWorkoutPlanScreen({super.key, required this.token});

  @override
  State<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final titleController = TextEditingController();
  final clientIdController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  // Dynamic exercise controllers
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> setsControllers = [];
  List<TextEditingController> repsControllers = [];

  @override
  void initState() {
    super.initState();
    addExercise(); // start with one exercise row
  }

  void addExercise() {
    setState(() {
      nameControllers.add(TextEditingController());
      setsControllers.add(TextEditingController());
      repsControllers.add(TextEditingController());
    });
  }

  void removeExercise(int index) {
    setState(() {
      nameControllers.removeAt(index);
      setsControllers.removeAt(index);
      repsControllers.removeAt(index);
    });
  }

  Future<void> submitPlan() async {
    if (titleController.text.isEmpty || clientIdController.text.isEmpty) {
      setState(() => errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final exercises = List.generate(nameControllers.length, (i) => {
      'name': nameControllers[i].text,
      'sets': int.tryParse(setsControllers[i].text) ?? 0,
      'reps': int.tryParse(repsControllers[i].text) ?? 0,
    });

    final data = await ApiService.post(
      context,
      '/workout_plans/',
      widget.token,
      {
        'title': titleController.text,
        'client_id': int.parse(clientIdController.text),
        'exercises': exercises,
      },
    );

    setState(() => isLoading = false);

    if (data != null) {
      Navigator.pop(context);
    } else {
      setState(() => errorMessage = 'Failed to create plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Plan Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: clientIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nameControllers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Exercise ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (nameControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeExercise(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Exercise Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: setsControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Sets',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: repsControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
            const SizedBox(height: 24),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitPlan,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}