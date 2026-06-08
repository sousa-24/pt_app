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
  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    try {
      final data = await ApiService.get(
        context,
        '/api/v1/my-contacts/',
        widget.token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        if (data is List) {
          clients = data
              .whereType<Map>()
              .map((client) => Map<String, dynamic>.from(client))
              .where((client) => client['id'] != null)
              .toList();
          errorMessage = null;
        } else {
          errorMessage = 'Nao foi possivel carregar os alunos.';
        }
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Nao foi possivel carregar os alunos.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Aluno',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('A carregar alunos...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Aluno',
          border: OutlineInputBorder(),
        ),
        child: Text(errorMessage!),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: widget.selectedClientId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Aluno',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Selecionar aluno'),
      items: clients.map((client) {
        final id = client['id'] is int
            ? client['id'] as int
            : int.tryParse(client['id'].toString());
        final name = client['name']?.toString().trim();
        final email = client['email']?.toString().trim();
        final label = name == null || name.isEmpty
            ? email ?? 'Aluno $id'
            : name;

        return DropdownMenuItem<int>(value: id, child: Text(label));
      }).toList(),
      onChanged: widget.onChanged,
    );
  }
}
