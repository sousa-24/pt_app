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
    final data = await ApiService.get(context, '/nutri_plans/', widget.token);
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
                        ...plan['items'].map<Widget>((item) {
                          return ListTile(
                            leading: const Icon(Icons.restaurant),
                            title: Text(item['name']),
                            subtitle: Text(
                              'Calories: ${item['calories']} | P: ${item['protein']}g | C: ${item['carbs']}g | F: ${item['fats']}g',
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
    );
  }
}