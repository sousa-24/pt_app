import 'package:flutter/material.dart';
import 'api_service.dart';
import 'l10n/gen/app_localizations.dart';

class SessionsScreen extends StatefulWidget {
  final String token;
  final String role;

  const SessionsScreen({super.key, required this.token, this.role = 'client'});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List sessions = [];
  List groupSessions = [];
  List availableGroupSessions = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isTrainer => widget.role == 'trainer';

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    try {
      final data = await ApiService.get(
        context,
        '/api/v1/training_sessions/',
        widget.token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      setState(() {
        if (data is List) {
          sessions = data;
          errorMessage = null;
        } else {
          errorMessage = getApiErrorMessage(data) ?? l10n.sessionsLoadError;
        }
        isLoading = false;
      });

      fetchGroupSessions();
      if (widget.role == 'client') {
        fetchAvailableGroupSessions();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = AppLocalizations.of(context)!.serverContactError;
        isLoading = false;
      });
    }
  }

  Future<void> fetchGroupSessions() async {
    final data = await ApiService.get(
      context,
      '/api/v1/group_sessions/',
      widget.token,
    );
    if (!mounted || data is! List) return;

    setState(() {
      groupSessions = data;
    });
  }

  Future<void> fetchAvailableGroupSessions() async {
    final data = await ApiService.get(
      context,
      '/api/v1/group_sessions/available',
      widget.token,
    );
    if (!mounted || data is! List) return;

    setState(() {
      availableGroupSessions = data;
    });
  }

  Future<void> enrollGroupSession(dynamic session) async {
    final sessionId = session is Map ? session['id'] : null;
    if (sessionId == null) return;

    final data = await ApiService.post(
      context,
      '/api/v1/group_sessions/$sessionId/enroll',
      widget.token,
      {},
    );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (data is Map && data['id'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enrollmentSuccessMessage)),
      );
      fetchSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getApiErrorMessage(data) ?? l10n.enrollmentError),
        ),
      );
    }
  }

  Future<void> editSession(dynamic session, {required bool isGroup}) async {
    final sessionMap = session is Map<String, dynamic>
        ? session
        : <String, dynamic>{};
    final initialDate = DateTime.tryParse(sessionMap['date']?.toString() ?? '');
    DateTime? selectedDate = initialDate;
    TimeOfDay? selectedTime = initialDate == null
        ? null
        : TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);
    String status = sessionMap['status']?.toString() ?? 'scheduled';
    final notesController = TextEditingController(
      text: sessionMap['notes']?.toString() ?? '',
    );
    final maxStudentsController = TextEditingController(
      text: sessionMap['max_students']?.toString() ?? '',
    );

    final l10n = AppLocalizations.of(context)!;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isGroup ? l10n.editGroupClassTitle : l10n.editSessionTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedDate ??
                                now.add(const Duration(hours: 24)),
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          selectedDate == null
                              ? l10n.dateLabel
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime?.format(context) ?? l10n.timeLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: l10n.statusLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text(l10n.sessionStatusScheduled),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text(l10n.sessionStatusCompleted),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text(l10n.sessionStatusCancelled),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
                if (isGroup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxStudentsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.maxStudentsLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.notesLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;

    if (selectedDate == null || selectedTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chooseDateAndTimeMessage)));
      return;
    }

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    final dateChanged =
        initialDate == null ||
        initialDate.year != dateTime.year ||
        initialDate.month != dateTime.month ||
        initialDate.day != dateTime.day ||
        initialDate.hour != dateTime.hour ||
        initialDate.minute != dateTime.minute;

    final endpoint = isGroup
        ? '/api/v1/group_sessions/${sessionMap['id']}'
        : '/api/v1/training_sessions/${sessionMap['id']}';
    final body = <String, dynamic>{
      'notes': notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      'status': status,
    };
    if (dateChanged) {
      body['date'] = dateTime.toIso8601String();
    }

    if (isGroup) {
      final maxStudents = int.tryParse(maxStudentsController.text.trim());
      if (maxStudents == null || maxStudents < 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.validMaxStudentsMessage)),
        );
        return;
      }
      body['max_students'] = maxStudents;
    }

    final data = await ApiService.put(context, endpoint, widget.token, body);
    if (!mounted) return;

    if (data is Map && data['id'] != null) {
      fetchSessions();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionUpdatedMessage)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getApiErrorMessage(data) ?? l10n.sessionUpdateError,
          ),
        ),
      );
    }
  }

  Future<void> deleteSession(dynamic session, {required bool isGroup}) async {
    final sessionMap = session is Map<String, dynamic>
        ? session
        : <String, dynamic>{};
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGroup ? l10n.deleteClassTitle : l10n.deleteSessionTitle),
        content: Text(l10n.actionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final endpoint = isGroup
        ? '/api/v1/group_sessions/${sessionMap['id']}'
        : '/api/v1/training_sessions/${sessionMap['id']}';
    final data = await ApiService.delete(context, endpoint, widget.token);
    if (!mounted) return;

    if (data is Map && data['message'] != null) {
      fetchSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGroup ? l10n.classDeletedMessage : l10n.sessionDeletedMessage,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getApiErrorMessage(data) ?? l10n.sessionDeleteError,
          ),
        ),
      );
    }
  }

  String? getApiErrorMessage(dynamic data) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return null;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'scheduled':
        return l10n.sessionStatusScheduled;
      case 'completed':
        return l10n.sessionStatusCompleted;
      case 'cancelled':
        return l10n.sessionStatusCancelled;
      default:
        return status;
    }
  }

  String formatSessionDate(String? rawDate, AppLocalizations l10n) {
    if (rawDate == null) return l10n.dateToBeDefinedLabel;

    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return l10n.dateTimeAt('$day/$month/$year', '$hour:$minute');
  }

  String groupSessionLabel(dynamic session, AppLocalizations l10n) {
    final registered = session is Map ? session['registered_students'] ?? 0 : 0;
    final maxStudents = session is Map ? session['max_students'] ?? '-' : '-';
    return l10n.groupClassLabel(registered.toString(), maxStudents.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mySessionsTitle)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView(
              children: [
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(l10n.noIndividualSessionsMessage),
                    ),
                  )
                else
                  ...sessions.map((s) => _sessionCard(s, l10n)),
                if (groupSessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      l10n.groupClassesTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...groupSessions.map((s) => _groupSessionCard(s, l10n)),
                ],
                if (widget.role == 'client' &&
                    availableGroupSessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      l10n.availableGroupClassesTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...availableGroupSessions.map(
                    (session) => _groupSessionCard(
                      session,
                      l10n,
                      action: TextButton.icon(
                        onPressed: () => enrollGroupSession(session),
                        icon: const Icon(Icons.how_to_reg),
                        label: Text(l10n.enrollMeAction),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _trainerActions(dynamic session, AppLocalizations l10n, {required bool isGroup}) {
    if (!isTrainer) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.edit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => editSession(session, isGroup: isGroup),
        ),
        IconButton(
          tooltip: l10n.delete,
          icon: const Icon(Icons.delete_outline),
          color: Colors.redAccent,
          onPressed: () => deleteSession(session, isGroup: isGroup),
        ),
      ],
    );
  }

  Widget _sessionCard(dynamic session, AppLocalizations l10n) {
    final status = session is Map ? session['status']?.toString() ?? '' : '';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(l10n.sessionOnDate(formatSessionDate(session['date'], l10n))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.individualSessionLabel),
            if (session['notes'] != null) Text(session['notes']),
          ],
        ),
        trailing: isTrainer
            ? _trainerActions(session, l10n, isGroup: false)
            : _statusBadge(status, l10n),
      ),
    );
  }

  Widget _groupSessionCard(dynamic session, AppLocalizations l10n, {Widget? action}) {
    final status = session is Map ? session['status']?.toString() ?? '' : '';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: Text(l10n.classOnDate(formatSessionDate(session['date'], l10n))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupSessionLabel(session, l10n)),
            if (session['notes'] != null) Text(session['notes']),
          ],
        ),
        trailing:
            action ??
            (isTrainer
                ? _trainerActions(session, l10n, isGroup: true)
                : _statusBadge(status, l10n)),
      ),
    );
  }

  Widget _statusBadge(String status, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        getStatusLabel(status, l10n),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
