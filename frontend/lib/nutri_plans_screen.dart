import 'package:flutter/material.dart';
import 'api_service.dart';
import 'create_nutri_plans_screen.dart';

class NutriPlansScreen extends StatefulWidget {
  final String token;
  final String role;

  const NutriPlansScreen({
    super.key,
    required this.token,
    this.role = 'client',
  });

  @override
  State<NutriPlansScreen> createState() => _NutriPlansScreenState();
}

class _NutriPlansScreenState extends State<NutriPlansScreen> {
  List plans = [];
  bool isLoading = true;
  String errorMessage = '';

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

  Future<void> editPlan(Map<String, dynamic> plan) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateNutriPlanScreen(token: widget.token, existingPlan: plan),
      ),
    );

    if (updated == true) {
      fetchPlans();
    }
  }

  Future<void> deletePlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar plano alimentar?'),
        content: Text(
          'Queres apagar "${plan['title'] ?? 'este plano'}"? Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final data = await ApiService.delete(
      context,
      '/api/v1/nutri_plans/${plan['id']}',
      widget.token,
    );
    if (!mounted) return;

    if (data is Map && data['message'] != null) {
      fetchPlans();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plano alimentar apagado.')));
    } else {
      setState(() => errorMessage = 'Nao foi possivel apagar o plano.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planos Alimentares')),
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
          ? const Center(child: Text('Ainda nao existem planos alimentares.'))
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
                  trailing: isTrainer
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar plano alimentar',
                              icon: const Icon(Icons.edit_outlined),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => editPlan(planMap),
                            ),
                            IconButton(
                              tooltip: 'Apagar plano alimentar',
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.redAccent,
                              onPressed: () => deletePlan(planMap),
                            ),
                          ],
                        )
                      : null,
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
                            leading: const Icon(Icons.restaurant_menu),
                            title: Text(mealMap['name'] ?? 'Refeicao'),
                            subtitle: const Text('Refeicao'),
                          ),
                          ...List<Widget>.from(
                            foodItems.map((item) {
                              final food = item is Map<String, dynamic>
                                  ? item
                                  : <String, dynamic>{};
                              return ListTile(
                                leading: const Icon(Icons.food_bank),
                                title: Text(food['name'] ?? 'Alimento'),
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
