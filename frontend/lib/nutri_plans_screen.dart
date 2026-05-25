import 'package:flutter/material.dart';
import 'api_service.dart';

class NutriPlansScreen extends StatefulWidget {
  final String token;

  const NutriPlansScreen({super.key, required this.token});

  @override
  State<NutriPlansScreen> createState() => _NutriPlansScreenState();
}

class _NutriPlansScreenState extends State<NutriPlansScreen> {
  List plans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final data = await ApiService.get(context, '/api/v1/nutri_plans/', widget.token);
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
      appBar: AppBar(
        title: const Text('Nutrition Plans'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
              ? const Center(child: Text('No nutrition plans yet'))
              : ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return ExpansionTile(
                      title: Text(plan['title']),
                      subtitle: Text('Created: ${plan['created_at']}'),
                      children: [
                        ...List<Widget>.from(
                          (plan['meals'] as List<dynamic>).expand((meal) {
                            final mealMap = meal as Map<String, dynamic>;
                            return [
                              ListTile(
                                leading: const Icon(Icons.restaurant_menu),
                                title: Text(mealMap['name'] ?? 'Meal'),
                                subtitle: const Text('Meal'),
                              ),
                              ...List<Widget>.from(
                                (mealMap['food_items'] as List<dynamic>).map((item) {
                                  final food = item as Map<String, dynamic>;
                                  return ListTile(
                                    leading: const Icon(Icons.food_bank),
                                    title: Text(food['name'] ?? 'Food Item'),
                                    subtitle: Text(
                                      'W: ${food['weight']}g • Cals: ${food['calories']} • P: ${food['protein']}g • C: ${food['carbs']}g • F: ${food['fats']}g',
                                    ),
                                  );
                                }).toList(),
                              ),
                            ];
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}