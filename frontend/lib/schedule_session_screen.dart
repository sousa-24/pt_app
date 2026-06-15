import 'package:flutter/material.dart';
import 'api_service.dart';
import 'client_selector.dart';
import 'l10n/gen/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final maxStudents = int.tryParse(maxStudentsController.text);
    final dateTime = selectedDateTime;

    if (dateTime == null) {
      setState(() => errorMessage = l10n.chooseDateAndTimeMessage);
      return;
    }

    if (sessionType == 'individual' && selectedClientId == null) {
      setState(() => errorMessage = l10n.selectStudentDateTimeMessage);
      return;
    }

    if (sessionType == 'group' && (maxStudents == null || maxStudents < 1)) {
      setState(() => errorMessage = l10n.validMaxStudentsMessage);
      return;
    }

    final now = DateTime.now();
    final earliestDateTime = now.add(const Duration(hours: 24));

    if (dateTime.isBefore(now)) {
      setState(() {
        errorMessage = l10n.sessionPastDateError;
      });
      return;
    }

    if (dateTime.isBefore(earliestDateTime)) {
      setState(() {
        errorMessage = l10n.sessionTooSoonError;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final String endpoint;
    final Map<String, dynamic> body;

    if (sessionType == 'group') {
      endpoint = '/api/v1/group_sessions/';
      body = {
        'date': dateTime.toIso8601String(),
        'max_students': maxStudents,
        'notes': notesController.text.isEmpty ? null : notesController.text,
      };
    } else {
      endpoint = '/api/v1/training_sessions/';
      body = {
        'client_id': selectedClientId,
        'date': dateTime.toIso8601String(),
        'notes': notesController.text.isEmpty ? null : notesController.text,
      };
    }

    final data = await ApiService.post(context, endpoint, widget.token, body);

    if (!mounted) return;

    setState(() => isLoading = false);

    if (data is Map && data['id'] != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.successTitle),
          content: Text(l10n.schedulingSuccessMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.okAction),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        errorMessage = getApiErrorMessage(data) ?? l10n.sessionScheduleError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleSessionTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'individual',
                  icon: const Icon(Icons.person_outline),
                  label: Text(l10n.individualOptionLabel),
                ),
                ButtonSegment(
                  value: 'group',
                  icon: const Icon(Icons.groups_outlined),
                  label: Text(l10n.groupOptionLabel),
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
                decoration: InputDecoration(
                  labelText: l10n.maxStudentsLabel,
                  border: const OutlineInputBorder(),
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
                          ? l10n.chooseDateAction
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
                          ? l10n.chooseTimeAction
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
              decoration: InputDecoration(
                labelText: l10n.notesOptionalLabel,
                border: const OutlineInputBorder(),
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
                            ? l10n.createGroupClassAction
                            : l10n.scheduleSessionTitle,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
