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
              'Não foi possível carregar as sessões agendadas.';
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
        errorMessage = 'Não foi possível contactar o servidor.';
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
        const SnackBar(content: Text('Inscrição realizada com sucesso.')),
      );
      fetchSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getApiErrorMessage(data) ?? 'Não foi possível fazer a inscrição.',
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
        return 'Concluída';
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

    return '$day/$month/$year às $hour:$minute';
  }

  String groupSessionLabel(dynamic session) {
    final registered = session is Map ? session['registered_students'] ?? 0 : 0;
    final maxStudents = session is Map ? session['max_students'] ?? '-' : '-';
    return 'Aula em grupo · $registered/$maxStudents inscritos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('As minhas sessões')),
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
                      child: Text('Não existem sessões individuais agendadas'),
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
                      'Aulas em grupo disponíveis',
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

  Widget _sessionCard(dynamic session) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text('Sessão em ${formatSessionDate(session['date'])}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sessão individual'),
            if (session['notes'] != null) Text(session['notes']),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(session['status']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getStatusLabel(session['status']),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _groupSessionCard(dynamic session, {Widget? action}) {
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
        trailing: action ?? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(session['status']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getStatusLabel(session['status']),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
