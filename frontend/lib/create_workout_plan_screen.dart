import 'package:flutter/material.dart';
import 'api_service.dart';
import 'client_selector.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final String token;

  const CreateWorkoutPlanScreen({super.key, required this.token});

  @override
  State<CreateWorkoutPlanScreen> createState() =>
      _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final titleController = TextEditingController();
  int? selectedClientId;
  bool isLoading = false;
  String errorMessage = '';

  // Dynamic exercise controllers
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> setsControllers = [];
  List<TextEditingController> repsControllers = [];

  @override
  void initState() {
    super.initState();
    addExercise();
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final controller in nameControllers) {
      controller.dispose();
    }
    for (final controller in setsControllers) {
      controller.dispose();
    }
    for (final controller in repsControllers) {
      controller.dispose();
    }
    super.dispose();
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
      nameControllers.removeAt(index).dispose();
      setsControllers.removeAt(index).dispose();
      repsControllers.removeAt(index).dispose();
    });
  }

  Future<void> submitPlan() async {
    final title = titleController.text.trim();

    if (title.isEmpty || selectedClientId == null) {
      setState(() => errorMessage = 'Preenche o título e seleciona um aluno.');
      return;
    }

    final exercises = <Map<String, dynamic>>[];
    for (var i = 0; i < nameControllers.length; i++) {
      final name = nameControllers[i].text.trim();
      final sets = int.tryParse(setsControllers[i].text.trim());
      final reps = int.tryParse(repsControllers[i].text.trim());

      if (name.isEmpty ||
          sets == null ||
          reps == null ||
          sets <= 0 ||
          reps <= 0) {
        setState(() {
          errorMessage =
              'Preenche o nome, as séries e as repetições de todos os exercícios.';
        });
        return;
      }

      exercises.add({'name': name, 'sets': sets, 'reps': reps});
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.post(
        context,
        '/api/v1/workout_plans/',
        widget.token,
        {'title': title, 'client_id': selectedClientId, 'exercises': exercises},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (data is Map<String, dynamic> && data['id'] != null) {
        Navigator.pop(context, true);
      } else {
        setState(
          () => errorMessage = 'Não foi possível criar o plano de treino.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Não foi possível contactar o servidor.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Plano de Treino')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título do plano',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ClientSelector(
              token: widget.token,
              selectedClientId: selectedClientId,
              onChanged: (clientId) {
                setState(() => selectedClientId = clientId);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Exercícios',
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
                            Text(
                              'Exercício ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (nameControllers.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeExercise(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Nome do exercício',
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
                                  labelText: 'Séries',
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
                                  labelText: 'Repetições',
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
              label: const Text('Adicionar exercício'),
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
                    : const Text('Criar plano'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
