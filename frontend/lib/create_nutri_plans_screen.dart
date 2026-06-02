import 'package:flutter/material.dart';
import 'api_service.dart';
import 'client_selector.dart';

class CreateNutriPlanScreen extends StatefulWidget {
  final String token;

  const CreateNutriPlanScreen({super.key, required this.token});

  @override
  State<CreateNutriPlanScreen> createState() => _CreateNutriPlanScreenState();
}

class _CreateNutriPlanScreenState extends State<CreateNutriPlanScreen> {
  final titleController = TextEditingController();
  int? selectedClientId;
  bool isLoading = false;
  String errorMessage = '';

  // Each meal has a name and a list of food items
  List<Map<String, dynamic>> meals = [];

  @override
  void initState() {
    super.initState();
    addMeal();
  }

  void addMeal() {
    setState(() {
      meals.add({'name': TextEditingController(), 'food_items': []});
    });
  }

  void removeMeal(int mealIndex) {
    setState(() {
      meals.removeAt(mealIndex);
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
      meals[mealIndex]['food_items'].removeAt(foodIndex);
    });
  }

  Future<void> submitPlan() async {
    if (titleController.text.isEmpty || selectedClientId == null) {
      setState(() => errorMessage = 'Preenche o título e seleciona um aluno.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final mealsData = meals.map((meal) {
      final foodItems = (meal['food_items'] as List)
          .map(
            (food) => {
              'name': food['name'].text,
              'weight': double.tryParse(food['weight'].text) ?? 0,
              'calories': double.tryParse(food['calories'].text) ?? 0,
              'protein': double.tryParse(food['protein'].text) ?? 0,
              'carbs': double.tryParse(food['carbs'].text) ?? 0,
              'fats': double.tryParse(food['fats'].text) ?? 0,
            },
          )
          .toList();

      return {'name': meal['name'].text, 'food_items': foodItems};
    }).toList();

    try {
      final data =
          await ApiService.post(context, '/api/v1/nutri_plans/', widget.token, {
            'title': titleController.text,
            'client_id': selectedClientId,
            'meals': mealsData,
          }).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (data is Map<String, dynamic> && data['id'] != null) {
        Navigator.pop(context, true);
      } else {
        setState(
          () => errorMessage = 'Não foi possível criar o plano alimentar.',
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
      appBar: AppBar(title: const Text('Criar Plano Alimentar')),
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
              'Refeições',
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
                              'Refeição ${mealIndex + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (meals.length > 1)
                              IconButton(
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
                            labelText: 'Nome da refeição (ex.: Pequeno-almoço)',
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
                                              labelText: 'Weight (g)',
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
                                              labelText: 'Calories',
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
                                              labelText: 'Protein',
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
                                              labelText: 'Carbs',
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
                                              labelText: 'Fats',
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
              label: const Text('Adicionar refeição'),
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
