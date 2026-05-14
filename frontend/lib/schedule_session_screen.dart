import 'package:flutter/material.dart';
import 'api_service.dart';

class ScheduleSessionScreen extends StatefulWidget {
  final String token;

  const ScheduleSessionScreen({super.key, required this.token});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final clientIdController = TextEditingController();
  final notesController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  Future<void> submitSession() async {
    if (clientIdController.text.isEmpty || selectedDate == null || selectedTime == null) {
      setState(() => errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final data = await ApiService.post(
      context,
      '/training_sessions/',
      widget.token,
      {
        'client_id': int.parse(clientIdController.text),
        'date': dateTime.toIso8601String(),
        'notes': notesController.text.isEmpty ? null : notesController.text,
      },
    );

    setState(() => isLoading = false);

    if (data != null) {
      Navigator.pop(context);
    } else {
      setState(() => errorMessage = 'Failed to schedule session');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: clientIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? 'Pick Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime == null
                        ? 'Pick Time'
                        : selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitSession,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Schedule Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}