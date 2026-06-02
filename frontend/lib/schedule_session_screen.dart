import 'package:flutter/material.dart';
import 'api_service.dart';
import 'client_selector.dart';

class ScheduleSessionScreen extends StatefulWidget {
  final String token;

  const ScheduleSessionScreen({super.key, required this.token});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final maxStudentsController = TextEditingController(text: '10');
  final notesController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int? selectedClientId;
  String sessionType = 'individual';
  bool isLoading = false;
  String errorMessage = '';

  Future<void> pickDate() async {
    final now = DateTime.now();
    final earliestDate = now.add(const Duration(hours: 24));
    final date = await showDatePicker(
      context: context,
      initialDate: earliestDate,
      firstDate: DateTime(
        earliestDate.year,
        earliestDate.month,
        earliestDate.day,
      ),
      lastDate: now.add(const Duration(days: 365)),
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

  DateTime? get selectedDateTime {
    if (selectedDate == null || selectedTime == null) return null;

    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  String? getApiErrorMessage(dynamic data) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }

    return null;
  }

  Future<void> submitSession() async {
    final maxStudents = int.tryParse(maxStudentsController.text);
    final dateTime = selectedDateTime;

    if (dateTime == null) {
      setState(() => errorMessage = 'Escolhe a data e a hora.');
      return;
    }

    if (sessionType == 'individual' && selectedClientId == null) {
      setState(() => errorMessage = 'Seleciona o aluno, a data e a hora.');
      return;
    }

    if (sessionType == 'group' && (maxStudents == null || maxStudents < 1)) {
      setState(() => errorMessage = 'Indica um limite de alunos valido.');
      return;
    }

    final now = DateTime.now();
    final earliestDateTime = now.add(const Duration(hours: 24));

    if (dateTime.isBefore(now)) {
      setState(() {
        errorMessage =
            'A sessão de treino não pode ser agendada para uma data/hora passada.';
      });
      return;
    }

    if (dateTime.isBefore(earliestDateTime)) {
      setState(() {
        errorMessage =
            'A sessão de treino deve ser agendada com pelo menos 24 horas de antecedência.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final data = await ApiService.post(
      context,
      '/api/v1/training_sessions/',
      widget.token,
      {
        'client_id': sessionType == 'individual' ? selectedClientId : null,
        'date': dateTime.toIso8601String(),
        'session_type': sessionType,
        'max_students': sessionType == 'group' ? maxStudents : null,
        'notes': notesController.text.isEmpty ? null : notesController.text,
      },
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (data is Map && data['id'] != null) {
      Navigator.pop(context);
    } else {
      setState(() {
        errorMessage =
            getApiErrorMessage(data) ??
            'Não foi possível agendar a sessão de treino.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar sessão')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'individual',
                  icon: Icon(Icons.person_outline),
                  label: Text('Individual'),
                ),
                ButtonSegment(
                  value: 'group',
                  icon: Icon(Icons.groups_outlined),
                  label: Text('Grupo'),
                ),
              ],
              selected: {sessionType},
              onSelectionChanged: (values) {
                setState(() => sessionType = values.first);
              },
            ),
            const SizedBox(height: 16),
            if (sessionType == 'individual')
              ClientSelector(
                token: widget.token,
                selectedClientId: selectedClientId,
                onChanged: (clientId) {
                  setState(() => selectedClientId = clientId);
                },
              )
            else
              TextField(
                controller: maxStudentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite de alunos',
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
                    label: Text(
                      selectedDate == null
                          ? 'Escolher data'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      selectedTime == null
                          ? 'Escolher hora'
                          : selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
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
                    : Text(
                        sessionType == 'group'
                            ? 'Criar aula em grupo'
                            : 'Agendar sessão',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
