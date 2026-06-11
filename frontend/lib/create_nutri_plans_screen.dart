import 'package:flutter/material.dart';
import 'api_service.dart';
import 'client_selector.dart';

class CreateNutriPlanScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? existingPlan;

  const CreateNutriPlanScreen({
    super.key,
    required this.token,
    this.existingPlan,
  });

  @override
  State<CreateNutriPlanScreen> createState() => _CreateNutriPlanScreenState();
}

class _CreateNutriPlanScreenState extends State<CreateNutriPlanScreen> {
  final titleController = TextEditingController();
  int? selectedClientId;
  bool isLoading = false;
  String errorMessage = '';

  final List<Map<String, dynamic>> meals = [];

  bool get isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();

    final plan = widget.existingPlan;
    if (plan == null) {
      addMeal();
      return;
    }

    titleController.text = plan['title']?.toString() ?? '';
    selectedClientId = plan['client_id'] is int
        ? plan['client_id'] as int
        : null;

    final existingMeals = plan['meals'] is List ? plan['meals'] as List : [];
    if (existingMeals.isEmpty) {
      addMeal();
      return;
    }

    for (final meal in existingMeals) {
      final mealMap = meal is Map<String, dynamic> ? meal : <String, dynamic>{};
      final foodItems = mealMap['food_items'] is List
          ? mealMap['food_items'] as List
          : const [];

      meals.add({
        'name': TextEditingController(text: mealMap['name']?.toString() ?? ''),
        'food_items': foodItems.map((item) {
          final food = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return {
            'name': TextEditingController(text: food['name']?.toString() ?? ''),
            'weight': TextEditingController(
              text: food['weight']?.toString() ?? '',
            ),
            'calories': TextEditingController(
              text: food['calories']?.toString() ?? '',
            ),
            'protein': TextEditingController(
              text: food['protein']?.toString() ?? '',
            ),
            'carbs': TextEditingController(
              text: food['carbs']?.toString() ?? '',
            ),
            'fats': TextEditingController(text: food['fats']?.toString() ?? ''),
          };
        }).toList(),
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final meal in meals) {
      (meal['name'] as TextEditingController).dispose();
      for (final food in meal['food_items'] as List) {
        (food['name'] as TextEditingController).dispose();
        (food['weight'] as TextEditingController).dispose();
        (food['calories'] as TextEditingController).dispose();
        (food['protein'] as TextEditingController).dispose();
        (food['carbs'] as TextEditingController).dispose();
        (food['fats'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  void addMeal() {
    setState(() {
      meals.add({'name': TextEditingController(), 'food_items': []});
    });
  }

  void removeMeal(int mealIndex) {
    setState(() {
      final meal = meals.removeAt(mealIndex);
      (meal['name'] as TextEditingController).dispose();
      for (final food in meal['food_items'] as List) {
        _disposeFoodItem(food);
      }
    });
  }

  void addFoodItem(int mealIndex) {
    setState(() {
      meals[mealIndex]['food_items'].add({
        'name': TextEditingController(),
        'weight': TextEditingController(),
        'calories': TextEditingController(),
        'protein': TextEditingController(),
        'carbs': TextEditingController(),
        'fats': TextEditingController(),
      });
    });
  }

  void removeFoodItem(int mealIndex, int foodIndex) {
    setState(() {
      final food = meals[mealIndex]['food_items'].removeAt(foodIndex);
      _disposeFoodItem(food);
    });
  }

  void _disposeFoodItem(dynamic food) {
    (food['name'] as TextEditingController).dispose();
    (food['weight'] as TextEditingController).dispose();
    (food['calories'] as TextEditingController).dispose();
    (food['protein'] as TextEditingController).dispose();
    (food['carbs'] as TextEditingController).dispose();
    (food['fats'] as TextEditingController).dispose();
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

    final mealsData = <Map<String, dynamic>>[];
    for (final meal in meals) {
      final mealName = (meal['name'] as TextEditingController).text.trim();
      final foodItems = <Map<String, dynamic>>[];

      if (mealName.isEmpty) {
        setState(() => errorMessage = 'Preenche o nome de todas as refeicoes.');
        return;
      }

      for (final food in meal['food_items'] as List) {
        final name = (food['name'] as TextEditingController).text.trim();
        final weight = double.tryParse(
          (food['weight'] as TextEditingController).text.trim(),
        );
        final calories = double.tryParse(
          (food['calories'] as TextEditingController).text.trim(),
        );
        final protein = double.tryParse(
          (food['protein'] as TextEditingController).text.trim(),
        );
        final carbs = double.tryParse(
          (food['carbs'] as TextEditingController).text.trim(),
        );
        final fats = double.tryParse(
          (food['fats'] as TextEditingController).text.trim(),
        );

        if (name.isEmpty ||
            weight == null ||
            calories == null ||
            protein == null ||
            carbs == null ||
            fats == null) {
          setState(() {
            errorMessage =
                'Preenche todos os campos dos alimentos com valores validos.';
          });
          return;
        }

        foodItems.add({
          'name': name,
          'weight': weight,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fats': fats,
        });
      }

      mealsData.add({'name': mealName, 'food_items': foodItems});
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = isEditing
          ? await ApiService.put(
              context,
              '/api/v1/nutri_plans/${widget.existingPlan!['id']}',
              widget.token,
              {'title': title, 'meals': mealsData},
            ).timeout(const Duration(seconds: 10))
          : await ApiService.post(
              context,
              '/api/v1/nutri_plans/',
              widget.token,
              {
                'title': title,
                'client_id': selectedClientId,
                'meals': mealsData,
              },
            ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (data is Map<String, dynamic> && data['id'] != null) {
        setState(() => isLoading = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sucesso'),
            content: const Text('Plano alimentar criado com sucesso.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() {
          errorMessage =
              getApiErrorMessage(data) ??
              (isEditing
                  ? 'Nao foi possivel atualizar o plano alimentar.'
                  : 'Nao foi possivel criar o plano alimentar.');
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
          isEditing ? 'Editar Plano Alimentar' : 'Criar Plano Alimentar',
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
              'Refeicoes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              itemBuilder: (context, mealIndex) {
                final meal = meals[mealIndex];
                final foodItems = meal['food_items'] as List;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Refeicao ${mealIndex + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (meals.length > 1)
                              IconButton(
                                tooltip: 'Remover refeicao',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeMeal(mealIndex),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: meal['name'],
                          decoration: const InputDecoration(
                            labelText: 'Nome da refeicao',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Alimentos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: foodItems.length,
                          itemBuilder: (context, foodIndex) {
                            final food = foodItems[foodIndex];
                            return Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Item ${foodIndex + 1}'),
                                        IconButton(
                                          tooltip: 'Remover alimento',
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          onPressed: () => removeFoodItem(
                                            mealIndex,
                                            foodIndex,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextField(
                                      controller: food['name'],
                                      decoration: const InputDecoration(
                                        labelText: 'Nome do alimento',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: food['weight'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Peso (g)',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: food['calories'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Calorias',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: food['protein'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Proteina',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: food['carbs'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Hidratos',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: food['fats'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Gorduras',
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
                        OutlinedButton.icon(
                          onPressed: () => addFoodItem(mealIndex),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar alimento'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            OutlinedButton.icon(
              onPressed: addMeal,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar refeicao'),
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
