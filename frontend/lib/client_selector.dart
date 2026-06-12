import 'package:flutter/material.dart';

import 'api_service.dart';

class ClientSelector extends StatefulWidget {
  final String token;
  final int? selectedClientId;
  final ValueChanged<int?> onChanged;

  const ClientSelector({
    super.key,
    required this.token,
    required this.selectedClientId,
    required this.onChanged,
  });

  @override
  State<ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<ClientSelector> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/my-contacts/',
        widget.token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        _clients = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .where((item) => item['id'] != null)
                  .toList()
            : [];
        _error = data is List ? null : 'Nao foi possivel carregar os alunos.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clients = [];
        _error = 'Nao foi possivel carregar os alunos.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LinearProgressIndicator();
    }

    if (_error != null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Aluno',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(child: Text(_error!)),
            IconButton(
              tooltip: 'Tentar novamente',
              onPressed: _loadClients,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _clientExists(widget.selectedClientId)
          ? widget.selectedClientId
          : null,
      decoration: const InputDecoration(
        labelText: 'Aluno',
        border: OutlineInputBorder(),
      ),
      items: _clients.map((client) {
        final id = client['id'];
        return DropdownMenuItem<int>(
          value: id is int ? id : int.tryParse(id.toString()),
          child: Text(_clientLabel(client)),
        );
      }).toList(),
      onChanged: _clients.isEmpty ? null : widget.onChanged,
    );
  }

  bool _clientExists(int? clientId) {
    if (clientId == null) return false;
    return _clients.any((client) {
      final id = client['id'];
      return id == clientId || int.tryParse(id.toString()) == clientId;
    });
  }

  String _clientLabel(Map<String, dynamic> client) {
    final name = client['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = client['email']?.toString().trim();
    if (email != null && email.isNotEmpty) return email;

    return 'Aluno ${client['id']}';
  }
}
