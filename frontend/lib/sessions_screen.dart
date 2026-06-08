import 'package:flutter/material.dart';
import 'api_service.dart';

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

      setState(() {
        if (data is List) {
          sessions = data;
          errorMessage = null;
        } else {
          errorMessage =
              getApiErrorMessage(data) ??
              'Nao foi possivel carregar as sessoes agendadas.';
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
        errorMessage = 'Nao foi possivel contactar o servidor.';
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

    if (data is Map && data['id'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscricao realizada com sucesso.')),
      );
      fetchSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getApiErrorMessage(data) ?? 'Nao foi possivel fazer a inscricao.',
          ),
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

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isGroup ? 'Editar aula em grupo' : 'Editar sessao'),
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
                              ? 'Data'
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
                        label: Text(selectedTime?.format(context) ?? 'Hora'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text('Agendada'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Concluida'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelada'),
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
                    decoration: const InputDecoration(
                      labelText: 'Limite de alunos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
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
      ).showSnackBar(const SnackBar(content: Text('Escolhe a data e a hora.')));
      return;
    }

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final endpoint = isGroup
        ? '/api/v1/group_sessions/${sessionMap['id']}'
        : '/api/v1/training_sessions/${sessionMap['id']}';
    final body = <String, dynamic>{
      'date': dateTime.toIso8601String(),
      'notes': notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      'status': status,
    };

    if (isGroup) {
      final maxStudents = int.tryParse(maxStudentsController.text.trim());
      if (maxStudents == null || maxStudents < 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indica um limite de alunos valido.')),
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
      ).showSnackBar(const SnackBar(content: Text('Sessao atualizada.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getApiErrorMessage(data) ?? 'Nao foi possivel atualizar a sessao.',
          ),
        ),
      );
    }
  }

  Future<void> deleteSession(dynamic session, {required bool isGroup}) async {
    final sessionMap = session is Map<String, dynamic>
        ? session
        : <String, dynamic>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGroup ? 'Apagar aula?' : 'Apagar sessao?'),
        content: const Text('Esta acao nao pode ser desfeita.'),
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

    final endpoint = isGroup
        ? '/api/v1/group_sessions/${sessionMap['id']}'
        : '/api/v1/training_sessions/${sessionMap['id']}';
    final data = await ApiService.delete(context, endpoint, widget.token);
    if (!mounted) return;

    if (data is Map && data['message'] != null) {
      fetchSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isGroup ? 'Aula apagada.' : 'Sessao apagada.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getApiErrorMessage(data) ?? 'Nao foi possivel apagar a sessao.',
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

  String getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Agendada';
      case 'completed':
        return 'Concluida';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  String formatSessionDate(String? rawDate) {
    if (rawDate == null) return 'data por definir';

    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year as $hour:$minute';
  }

  String groupSessionLabel(dynamic session) {
    final registered = session is Map ? session['registered_students'] ?? 0 : 0;
    final maxStudents = session is Map ? session['max_students'] ?? '-' : '-';
    return 'Aula em grupo - $registered/$maxStudents inscritos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('As minhas sessoes')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView(
              children: [
                if (sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Nao existem sessoes individuais agendadas'),
                    ),
                  )
                else
                  ...sessions.map((s) => _sessionCard(s)),
                if (groupSessions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Aulas em grupo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...groupSessions.map((s) => _groupSessionCard(s)),
                ],
                if (widget.role == 'client' &&
                    availableGroupSessions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Aulas em grupo disponiveis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...availableGroupSessions.map(
                    (session) => _groupSessionCard(
                      session,
                      action: TextButton.icon(
                        onPressed: () => enrollGroupSession(session),
                        icon: const Icon(Icons.how_to_reg),
                        label: const Text('Inscrever-me'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _trainerActions(dynamic session, {required bool isGroup}) {
    if (!isTrainer) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => editSession(session, isGroup: isGroup),
        ),
        IconButton(
          tooltip: 'Apagar',
          icon: const Icon(Icons.delete_outline),
          color: Colors.redAccent,
          onPressed: () => deleteSession(session, isGroup: isGroup),
        ),
      ],
    );
  }

  Widget _sessionCard(dynamic session) {
    final status = session is Map ? session['status']?.toString() ?? '' : '';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text('Sessao em ${formatSessionDate(session['date'])}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sessao individual'),
            if (session['notes'] != null) Text(session['notes']),
          ],
        ),
        trailing: isTrainer
            ? _trainerActions(session, isGroup: false)
            : _statusBadge(status),
      ),
    );
  }

  Widget _groupSessionCard(dynamic session, {Widget? action}) {
    final status = session is Map ? session['status']?.toString() ?? '' : '';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: Text('Aula em ${formatSessionDate(session['date'])}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupSessionLabel(session)),
            if (session['notes'] != null) Text(session['notes']),
          ],
        ),
        trailing:
            action ??
            (isTrainer
                ? _trainerActions(session, isGroup: true)
                : _statusBadge(status)),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        getStatusLabel(status),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
