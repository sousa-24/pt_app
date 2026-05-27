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
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      final data = await ApiService.get(
        context,
        '/api/v1/nutri_plans/',
        widget.token,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      setState(() {
        if (data is List) {
          plans = data;
          errorMessage = '';
        } else {
          errorMessage = 'Nao foi possivel carregar os planos alimentares.';
        }
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Nao foi possivel contactar o servidor.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos Alimentares'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(errorMessage, textAlign: TextAlign.center),
                  ),
                )
              : plans.isEmpty
                  ? const Center(
                      child: Text('Ainda nao existem planos alimentares.'),
                    )
                  : ListView.builder(
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        final planMap = plan is Map<String, dynamic>
                            ? plan
                            : <String, dynamic>{};
                        final meals = planMap['meals'] is List
                            ? planMap['meals'] as List
                            : const [];

                        return ExpansionTile(
                          title: Text(planMap['title'] ?? 'Plano alimentar'),
                          subtitle: Text(
                            'Criado em: ${planMap['created_at'] ?? 'recentemente'}',
                          ),
                          children: [
                            ...List<Widget>.from(
                              meals.expand((meal) {
                                final mealMap = meal is Map<String, dynamic>
                                    ? meal
                                    : <String, dynamic>{};
                                final foodItems = mealMap['food_items'] is List
                                    ? mealMap['food_items'] as List
                                    : const [];

                                return [
                                  ListTile(
                                    leading:
                                        const Icon(Icons.restaurant_menu),
                                    title: Text(
                                      mealMap['name'] ?? 'Refeicao',
                                    ),
                                    subtitle: const Text('Refeicao'),
                                  ),
                                  ...List<Widget>.from(
                                    foodItems.map((item) {
                                      final food = item is Map<String, dynamic>
                                          ? item
                                          : <String, dynamic>{};
                                      return ListTile(
                                        leading: const Icon(Icons.food_bank),
                                        title: Text(
                                          food['name'] ?? 'Alimento',
                                        ),
                                        subtitle: Text(
                                          'Peso: ${food['weight']}g | '
                                          'Calorias: ${food['calories']} | '
                                          'Proteina: ${food['protein']}g | '
                                          'Hidratos: ${food['carbs']}g | '
                                          'Gordura: ${food['fats']}g',
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
