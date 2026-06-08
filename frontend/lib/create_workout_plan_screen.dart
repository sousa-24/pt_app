import 'package:flutter/material.dart';
import 'api_service.dart';
import 'client_selector.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? existingPlan;

  const CreateWorkoutPlanScreen({
    super.key,
    required this.token,
    this.existingPlan,
  });

  @override
  State<CreateWorkoutPlanScreen> createState() =>
      _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final titleController = TextEditingController();
  int? selectedClientId;
  bool isLoading = false;
  String errorMessage = '';

  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> setsControllers = [];
  final List<TextEditingController> repsControllers = [];

  bool get isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();

    final plan = widget.existingPlan;
    if (plan == null) {
      addExercise();
      return;
    }

    titleController.text = plan['title']?.toString() ?? '';
    selectedClientId = plan['client_id'] is int
        ? plan['client_id'] as int
        : null;

    final exercises = plan['exercises'] is List
        ? plan['exercises'] as List
        : [];
    if (exercises.isEmpty) {
      addExercise();
      return;
    }

    for (final exercise in exercises) {
      final exerciseMap = exercise is Map<String, dynamic>
          ? exercise
          : <String, dynamic>{};
      nameControllers.add(
        TextEditingController(text: exerciseMap['name']?.toString() ?? ''),
      );
      setsControllers.add(
        TextEditingController(text: exerciseMap['sets']?.toString() ?? ''),
      );
      repsControllers.add(
        TextEditingController(text: exerciseMap['reps']?.toString() ?? ''),
      );
    }
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

  String? getApiErrorMessage(dynamic data) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return null;
  }

  Future<void> submitPlan() async {
    final title = titleController.text.trim();

    if (title.isEmpty || selectedClientId == null) {
      setState(() => errorMessage = 'Preenche o titulo e seleciona um aluno.');
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
              'Preenche o nome, as series e as repeticoes de todos os exercicios.';
        });
        return;
      }

      exercises.add({'name': name, 'sets': sets, 'reps': reps});
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final payload = {
      'title': title,
      'client_id': selectedClientId,
      'exercises': exercises,
    };

    try {
      final data = isEditing
          ? await ApiService.put(
              context,
              '/api/v1/workout_plans/${widget.existingPlan!['id']}',
              widget.token,
              payload,
            ).timeout(const Duration(seconds: 10))
          : await ApiService.post(
              context,
              '/api/v1/workout_plans/',
              widget.token,
              payload,
            ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (data is Map<String, dynamic> && data['id'] != null) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          errorMessage =
              getApiErrorMessage(data) ??
              (isEditing
                  ? 'Nao foi possivel atualizar o plano de treino.'
                  : 'Nao foi possivel criar o plano de treino.');
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Nao foi possivel contactar o servidor.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Plano de Treino' : 'Criar Plano de Treino',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titulo do plano',
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
              'Exercicios',
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
                              'Exercicio ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (nameControllers.length > 1)
                              IconButton(
                                tooltip: 'Remover exercicio',
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
                            labelText: 'Nome do exercicio',
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
                                  labelText: 'Series',
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
                                  labelText: 'Repeticoes',
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
              label: const Text('Adicionar exercicio'),
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
                    : Text(isEditing ? 'Guardar alteracoes' : 'Criar plano'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
