import 'package:flutter/material.dart';
import 'api_service.dart';

class ProgressionScreen extends StatefulWidget {
  final String token;

  const ProgressionScreen({super.key, required this.token});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  List progression = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProgression();
  }

  Future<void> fetchProgression() async {
    final data = await ApiService.get(context, '/api/v1/progression/', widget.token);
    if (data != null) {
      setState(() {
        progression = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progression'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : progression.isEmpty
              ? const Center(child: Text('No progression data yet'))
              : ListView.builder(
                  itemCount: progression.length,
                  itemBuilder: (context, index) {
                    final entry = progression[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Date: ${entry['date']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry['weight'] != null)
                              Text('Weight: ${entry['weight']} kg'),
                            if (entry['body_fat_percentage'] != null)
                              Text('Body Fat: ${entry['body_fat_percentage']}%'),
                            if (entry['notes'] != null)
                              Text('Notes: ${entry['notes']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}