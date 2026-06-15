import 'package:flutter/material.dart';

import 'api_service.dart';
import 'l10n/gen/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sessions = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _clientNames = _clientNameMap(contacts, l10n);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = AppLocalizations.of(context)!.evaluationsLoadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEvaluation() async {
    final l10n = AppLocalizations.of(context)!;
    final session = _selectedSession;
    if (session == null) {
      setState(() => _message = l10n.selectSessionMessage);
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
        _message = l10n.evaluationSavedMessage;
        _isSaving = false;
      });
    } else {
      setState(() {
        _message = _apiError(data) ?? l10n.evaluationSaveError;
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
        _message = AppLocalizations.of(context)!.feedbackLoadError;
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

  String _clientName(dynamic clientId, AppLocalizations l10n) {
    final id = clientId is int ? clientId : int.tryParse(clientId.toString());
    if (id == null) return l10n.accountStudent;
    return _clientNames[id] ?? l10n.studentNumberLabel(id.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.evaluationsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_sessions.isEmpty)
            Center(child: Text(l10n.noEvaluableSessionsMessage))
          else ...[
            _evaluationForm(l10n),
            const SizedBox(height: 18),
            _feedbackPanel(l10n),
            const SizedBox(height: 18),
            Text(
              l10n.recentSessionsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._sessions.map((session) => _sessionCard(session, l10n)),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }

  Widget _evaluationForm(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.evaluateStudentPerformanceTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedSessionId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.sessionLabel,
                border: const OutlineInputBorder(),
              ),
              items: _sessions.map((session) {
                final id = session['id'] as int;
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    '${_clientName(session['client_id'], l10n)} - ${_formatDate(session['date'], l10n)}',
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
              decoration: InputDecoration(
                labelText: l10n.evaluationNotesLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveEvaluation,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: Text(_isSaving ? l10n.savingLabel : l10n.saveEvaluationAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> session, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(_clientName(session['client_id'], l10n)),
        subtitle: Text(_formatDate(session['date'], l10n)),
        trailing: Text(_statusLabel(session['status'], l10n)),
      ),
    );
  }

  Widget _feedbackPanel(AppLocalizations l10n) {
    if (_selectedSessionId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.selectSessionForFeedbackMessage),
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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noFeedbackForSessionMessage),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.studentFeedbackTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._feedback.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.ratingOutOf5Label(item['rating'].toString())),
                subtitle: Text(item['notes']?.toString() ?? l10n.noNotesMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(dynamic status, AppLocalizations l10n) {
  switch (status?.toString()) {
    case 'completed':
      return l10n.sessionStatusCompleted;
    case 'cancelled':
      return l10n.sessionStatusCancelled;
    default:
      return l10n.sessionStatusScheduled;
  }
}

String _formatDate(dynamic value, AppLocalizations l10n) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? l10n.noDate;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return l10n.dateTimeAt('$day/$month/${parsed.year}', '$hour:$minute');
}

String? _apiError(dynamic data) {
  if (data is Map && data['detail'] != null) return data['detail'].toString();
  return null;
}

Map<int, String> _clientNameMap(dynamic contacts, AppLocalizations l10n) {
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
        : l10n.studentNumberLabel(id.toString());
  }
  return result;
}
