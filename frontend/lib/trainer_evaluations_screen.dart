import 'package:flutter/material.dart';

import 'api_service.dart';

class TrainerEvaluationsScreen extends StatefulWidget {
  final String token;

  const TrainerEvaluationsScreen({super.key, required this.token});

  @override
  State<TrainerEvaluationsScreen> createState() =>
      _TrainerEvaluationsScreenState();
}

class _TrainerEvaluationsScreenState extends State<TrainerEvaluationsScreen> {
  final _notesController = TextEditingController();
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _feedback = [];
  Map<int, String> _clientNames = {};
  int? _selectedSessionId;
  int _rating = 5;
  bool _isLoading = true;
  bool _isLoadingFeedback = false;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final results = await Future.wait([
        ApiService.get(context, '/api/v1/training_sessions/', widget.token),
        ApiService.get(context, '/api/v1/my-contacts/', widget.token),
      ]).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final data = results[0];
      final contacts = results[1];
      setState(() {
        _sessions = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _clientNames = _clientNameMap(contacts);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Nao foi possivel carregar as sessoes.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEvaluation() async {
    final session = _selectedSession;
    if (session == null) {
      setState(() => _message = 'Seleciona uma sessao.');
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final data = await ApiService.post(
      context,
      '/api/v1/session-performance/',
      widget.token,
      {
        'session_id': session['id'],
        'client_id': session['client_id'],
        'performance_rating': _rating,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      },
    );
    if (!mounted) return;

    if (data is Map && data['id'] != null) {
      _notesController.clear();
      setState(() {
        _message = 'Avaliacao guardada com sucesso.';
        _isSaving = false;
      });
    } else {
      setState(() {
        _message = _apiError(data) ?? 'Nao foi possivel guardar a avaliacao.';
        _isSaving = false;
      });
    }
  }

  Future<void> _loadFeedback(int sessionId) async {
    setState(() {
      _isLoadingFeedback = true;
      _feedback = [];
    });

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/session-feedback/$sessionId',
        widget.token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        _feedback = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _isLoadingFeedback = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Nao foi possivel carregar o feedback do aluno.';
        _isLoadingFeedback = false;
      });
    }
  }

  Map<String, dynamic>? get _selectedSession {
    for (final session in _sessions) {
      if (session['id'] == _selectedSessionId) return session;
    }
    return null;
  }

  String _clientName(dynamic clientId) {
    final id = clientId is int ? clientId : int.tryParse(clientId.toString());
    if (id == null) return 'Aluno';
    return _clientNames[id] ?? 'Aluno #$id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_sessions.isEmpty)
            const Center(child: Text('Ainda nao existem sessoes para avaliar.'))
          else ...[
            _evaluationForm(),
            const SizedBox(height: 18),
            _feedbackPanel(),
            const SizedBox(height: 18),
            const Text(
              'Sessões recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._sessions.map(_sessionCard),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }

  Widget _evaluationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avaliar performance do aluno',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedSessionId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sessao',
                border: OutlineInputBorder(),
              ),
              items: _sessions.map((session) {
                final id = session['id'] as int;
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    '${_clientName(session['client_id'])} - ${_formatDate(session['date'])}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSessionId = value);
                if (value != null) {
                  _loadFeedback(value);
                }
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 5, label: Text('5')),
              ],
              selected: {_rating},
              onSelectionChanged: (value) {
                setState(() => _rating = value.first);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notas da avaliacao',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveEvaluation,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: Text(_isSaving ? 'A guardar...' : 'Guardar avaliacao'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> session) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(_clientName(session['client_id'])),
        subtitle: Text(_formatDate(session['date'])),
        trailing: Text(_statusLabel(session['status'])),
      ),
    );
  }

  Widget _feedbackPanel() {
    if (_selectedSessionId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Seleciona uma sessao para ver feedback do aluno.'),
        ),
      );
    }

    if (_isLoadingFeedback) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_feedback.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ainda nao existe feedback do aluno para esta sessao.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feedback do aluno',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._feedback.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_outline),
                title: Text('Nota ${item['rating']}/5'),
                subtitle: Text(item['notes']?.toString() ?? 'Sem notas.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(dynamic status) {
  switch (status?.toString()) {
    case 'completed':
      return 'Concluida';
    case 'cancelled':
      return 'Cancelada';
    default:
      return 'Agendada';
  }
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? 'Sem data';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} as $hour:$minute';
}

String? _apiError(dynamic data) {
  if (data is Map && data['detail'] != null) return data['detail'].toString();
  return null;
}

Map<int, String> _clientNameMap(dynamic contacts) {
  if (contacts is! List) return {};

  final result = <int, String>{};
  for (final item in contacts) {
    if (item is! Map) continue;
    final idValue = item['id'];
    final id = idValue is int ? idValue : int.tryParse(idValue.toString());
    if (id == null) continue;

    final name = item['name']?.toString().trim();
    final email = item['email']?.toString().trim();
    result[id] = name != null && name.isNotEmpty
        ? name
        : email != null && email.isNotEmpty
        ? email
        : 'Aluno #$id';
  }
  return result;
}
