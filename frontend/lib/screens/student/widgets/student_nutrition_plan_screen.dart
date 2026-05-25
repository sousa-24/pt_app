import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

class StudentNutritionPlanScreen extends StatefulWidget {
  final String? token;

  const StudentNutritionPlanScreen({
    super.key,
    required this.token,
  });

  @override
  State<StudentNutritionPlanScreen> createState() =>
      _StudentNutritionPlanScreenState();
}

class _StudentNutritionPlanScreenState
    extends State<StudentNutritionPlanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadNutritionPlans();
  }

  Future<void> _loadNutritionPlans() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Entre com login para acessar o plano alimentar.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await ApiService.get(
        context,
        '/nutri_plans/',
        token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        if (data is List) {
          _plans = List<Map<String, dynamic>>.from(data);
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Nao foi possivel carregar o plano alimentar agora.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meu Plano Alimentar',
          style: TextStyle(
            color: StudentTheme.darkText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          _MessageCard(message: _errorMessage!)
        else if (_plans.isEmpty)
          const _MessageCard(
            message: 'Ainda nao existe plano alimentar registado.',
          )
        else
          ..._plans.map((plan) => _NutritionPlanCard(plan: plan)),
      ],
    );
  }
}

class _NutritionPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;

  const _NutritionPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final meals = plan['meals'] is List ? plan['meals'] as List : const [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: StudentTheme.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(plan['title'], 'Plano alimentar'),
                      style: const TextStyle(
                        color: StudentTheme.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(plan['created_at']),
                      style: const TextStyle(
                        color: StudentTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (meals.isEmpty)
            const Text(
              'Este plano ainda nao tem refeicoes cadastradas.',
              style: TextStyle(
                color: StudentTheme.mutedText,
                fontSize: 14,
              ),
            )
          else
            ...meals.map((meal) {
              if (meal is! Map<String, dynamic>) return const SizedBox.shrink();
              return _MealSection(meal: meal);
            }),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final Map<String, dynamic> meal;

  const _MealSection({required this.meal});

  @override
  Widget build(BuildContext context) {
    final foodItems =
        meal['food_items'] is List ? meal['food_items'] as List : const [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF242426),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A3A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(meal['name'], 'Refeicao'),
            style: const TextStyle(
              color: StudentTheme.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (foodItems.isEmpty)
            const Text(
              'Sem alimentos nesta refeicao.',
              style: TextStyle(
                color: StudentTheme.mutedText,
                fontSize: 13,
              ),
            )
          else
            ...foodItems.map((food) {
              if (food is! Map<String, dynamic>) return const SizedBox.shrink();
              return _FoodItemRow(food: food);
            }),
        ],
      ),
    );
  }
}

class _FoodItemRow extends StatelessWidget {
  final Map<String, dynamic> food;

  const _FoodItemRow({required this.food});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.circle,
            color: StudentTheme.blue,
            size: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(food['name'], 'Alimento'),
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatNumber(food['weight'], 'g')} | '
                  '${_formatNumber(food['calories'], 'kcal')} | '
                  'P ${_formatNumber(food['protein'], 'g')} | '
                  'C ${_formatNumber(food['carbs'], 'g')} | '
                  'G ${_formatNumber(food['fats'], 'g')}',
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Text(
        message,
        style: const TextStyle(
          color: StudentTheme.mutedText,
          fontSize: 15,
        ),
      ),
    );
  }
}

String _text(dynamic value, String fallback) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _formatNumber(dynamic value, String suffix) {
  if (value == null) return '-';
  final number = value is num ? value : num.tryParse(value.toString());
  if (number == null) return '-';
  return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 1)} $suffix';
}

String _formatDate(dynamic value) {
  if (value == null) return 'Sem data';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  return 'Criado em $day/$month/$year';
}
