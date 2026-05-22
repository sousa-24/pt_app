import 'package:flutter/material.dart';
import 'api_service.dart';

class CreateNutriPlanScreen extends StatefulWidget {
  final String token;

  const CreateNutriPlanScreen({super.key, required this.token});

  @override
  State<CreateNutriPlanScreen> createState() => _CreateNutriPlanScreenState();
}

class _CreateNutriPlanScreenState extends State<CreateNutriPlanScreen> {
  final titleController = TextEditingController();
  final clientIdController = TextEditingController();
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
    if (titleController.text.isEmpty || clientIdController.text.isEmpty) {
      setState(() => errorMessage = 'Please fill in all fields');
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
              'calories': double.tryParse(food['calories'].text) ?? 0,
              'protein': double.tryParse(food['protein'].text) ?? 0,
              'carbs': double.tryParse(food['carbs'].text) ?? 0,
              'fats': double.tryParse(food['fats'].text) ?? 0,
            },
          )
          .toList();

      return {'name': meal['name'].text, 'food_items': foodItems};
    }).toList();

    final data = await ApiService.post(context, '/api/v1/nutri_plans/', widget.token, {
      'title': titleController.text,
      'client_id': int.parse(clientIdController.text),
      'meals': mealsData,
    });

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
      appBar: AppBar(title: const Text('Create Nutrition Plan')),
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
              'Meals',
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
                              'Meal ${mealIndex + 1}',
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
                            labelText: 'Meal Name (e.g. Breakfast)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Food Items',
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
                              ).colorScheme.surfaceVariant,
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
                                        labelText: 'Food Name',
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
                          label: const Text('Add Food Item'),
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
              label: const Text('Add Meal'),
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
