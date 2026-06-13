import 'package:flutter/material.dart';

import 'api_service.dart';
import 'client_selector.dart';

class TrainerPaymentsScreen extends StatefulWidget {
  final String token;

  const TrainerPaymentsScreen({super.key, required this.token});

  @override
  State<TrainerPaymentsScreen> createState() => _TrainerPaymentsScreenState();
}

class _TrainerPaymentsScreenState extends State<TrainerPaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _costController = TextEditingController();
  final _methodController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedClientId;
  DateTime? _dueDate;
  List<Map<String, dynamic>> _payments = [];
  Map<int, String> _clientNames = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _costController.dispose();
    _methodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get(context, '/api/v1/payments/', widget.token),
        ApiService.get(context, '/api/v1/my-contacts/', widget.token),
      ]).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final data = results[0];
      final contacts = results[1];
      setState(() {
        if (data is List) {
          _payments = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          _payments = [];
          _loadError =
              _apiError(data) ?? 'Nao foi possivel carregar as faturas.';
        }
        _clientNames = _clientNameMap(contacts);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Nao foi possivel carregar as faturas.';
        _isLoading = false;
      });
    }
  }

  Future<void> _createPayment() async {
    if (_selectedClientId == null) {
      setState(() => _message = 'Seleciona um aluno.');
      return;
    }
    if (_dueDate == null) {
      setState(() => _message = 'Escolhe a data de vencimento.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final data =
        await ApiService.post(context, '/api/v1/payments/', widget.token, {
          'client_id': _selectedClientId,
          'type_of_service': _serviceController.text.trim(),
          'cost': double.tryParse(_costController.text.replaceAll(',', '.')),
          'due_date': _dueDate!.toIso8601String().substring(0, 10),
          'payment_method': _methodController.text.trim().isEmpty
              ? null
              : _methodController.text.trim(),
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        });
    if (!mounted) return;

    if (data is Map && data['id'] != null) {
      _serviceController.clear();
      _costController.clear();
      _methodController.clear();
      _notesController.clear();
      setState(() {
        _message = 'Fatura criada com sucesso.';
        _isSaving = false;
      });
      _loadPayments();
    } else {
      setState(() {
        _message = _apiError(data) ?? 'Nao foi possivel criar a fatura.';
        _isSaving = false;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _updatePayment(
    Map<String, dynamic> payment,
    Map<String, dynamic> body,
    String successMessage,
  ) async {
    final id = payment['id'];
    if (id == null) return;

    final data = await ApiService.put(
      context,
      '/api/v1/payments/$id',
      widget.token,
      body,
    );
    if (!mounted) return;

    if (data is Map && data['id'] != null) {
      setState(() => _message = successMessage);
      _loadPayments();
    } else {
      setState(() {
        _message = _apiError(data) ?? 'Nao foi possivel atualizar a fatura.';
      });
    }
  }

  Future<void> _markAsPaid(Map<String, dynamic> payment) async {
    await _updatePayment(payment, {
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }, 'Fatura marcada como paga.');
  }

  Future<void> _cancelPayment(Map<String, dynamic> payment) async {
    await _updatePayment(payment, {'status': 'cancelled'}, 'Fatura cancelada.');
  }

  Future<void> _deletePayment(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar fatura?'),
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
    if (!mounted) return;

    final id = payment['id'];
    if (id == null) return;

    final data = await ApiService.delete(
      context,
      '/api/v1/payments/$id',
      widget.token,
    );
    if (!mounted) return;

    if (data is Map && data['message'] != null) {
      setState(() => _message = 'Fatura apagada.');
      _loadPayments();
    } else {
      setState(() {
        _message = _apiError(data) ?? 'Nao foi possivel apagar a fatura.';
      });
    }
  }

  Future<void> _editPayment(Map<String, dynamic> payment) async {
    final serviceController = TextEditingController(
      text: _text(payment['type_of_service']),
    );
    final costController = TextEditingController(
      text: payment['cost']?.toString() ?? '',
    );
    final methodController = TextEditingController(
      text: _text(payment['payment_method']),
    );
    final notesController = TextEditingController(
      text: _text(payment['notes']),
    );
    DateTime? dueDate = DateTime.tryParse(
      payment['due_date']?.toString() ?? '',
    );
    String status = payment['status']?.toString() ?? 'pending';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar fatura'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Servico',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'EUR ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pendente')),
                    DropdownMenuItem(value: 'paid', child: Text('Pago')),
                    DropdownMenuItem(value: 'overdue', child: Text('Atrasado')),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelado'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 3),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text(
                    dueDate == null
                        ? 'Data de vencimento'
                        : _formatDate(dueDate!.toIso8601String()),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: methodController,
                  decoration: const InputDecoration(
                    labelText: 'Metodo de pagamento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
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

    if (saved != true) {
      serviceController.dispose();
      costController.dispose();
      methodController.dispose();
      notesController.dispose();
      return;
    }

    final cost = double.tryParse(costController.text.replaceAll(',', '.'));
    if (serviceController.text.trim().isEmpty || cost == null || cost <= 0) {
      if (mounted) {
        setState(() => _message = 'Preenche servico e valor validos.');
      }
      serviceController.dispose();
      costController.dispose();
      methodController.dispose();
      notesController.dispose();
      return;
    }

    await _updatePayment(payment, {
      'type_of_service': serviceController.text.trim(),
      'cost': cost,
      'status': status,
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().substring(0, 10),
      'payment_method': methodController.text.trim().isEmpty
          ? null
          : methodController.text.trim(),
      'notes': notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      if (status == 'paid' && payment['paid_at'] == null)
        'paid_at': DateTime.now().toIso8601String(),
    }, 'Fatura atualizada.');

    serviceController.dispose();
    costController.dispose();
    methodController.dispose();
    notesController.dispose();
  }

  Map<String, dynamic>? get _nextPayment {
    final candidates =
        _payments.where((payment) {
          final status = payment['status']?.toString();
          return status == 'pending' || status == 'overdue';
        }).toList()..sort((a, b) {
          final aDate = DateTime.tryParse(a['due_date']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['due_date']?.toString() ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });

    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _paymentForm(),
          const SizedBox(height: 16),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_message!),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            _StatusCard(message: _loadError!)
          else if (_payments.isEmpty)
            const _StatusCard(message: 'Ainda nao existem faturas.')
          else ...[
            _PaymentSummaryCard(
              payment: _nextPayment,
              clientLabel: _clientLabel(_nextPayment?['client_id']),
            ),
            const SizedBox(height: 12),
            ..._payments.map(_paymentCard),
          ],
        ],
      ),
    );
  }

  Widget _paymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nova fatura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClientSelector(
                token: widget.token,
                selectedClientId: _selectedClientId,
                onChanged: (clientId) {
                  setState(() => _selectedClientId = clientId);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serviceController,
                decoration: const InputDecoration(
                  labelText: 'Servico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Obrigatorio'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'EUR ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (amount == null || amount <= 0) return 'Valor invalido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _dueDate == null
                      ? 'Data de vencimento'
                      : _formatDate(_dueDate!.toIso8601String()),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _methodController,
                decoration: const InputDecoration(
                  labelText: 'Metodo de pagamento (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _createPayment,
                  icon: const Icon(Icons.receipt_long),
                  label: Text(_isSaving ? 'A criar...' : 'Criar fatura'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> payment) {
    final clientLabel = _clientLabel(payment['client_id']);
    return Card(
      child: ListTile(
        onTap: () => _showPaymentDetails(payment),
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(payment['type_of_service']?.toString() ?? 'Fatura'),
        subtitle: Text('$clientLabel | ${_paymentDateLabel(payment)}'),
        trailing: Wrap(
          spacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('EUR ${payment['cost']}'),
                Text(
                  _statusLabel(payment['status']),
                  style: TextStyle(
                    color: _statusColor(payment['status']),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: 'Acoes da fatura',
              onSelected: (value) {
                switch (value) {
                  case 'paid':
                    _markAsPaid(payment);
                    break;
                  case 'edit':
                    _editPayment(payment);
                    break;
                  case 'cancel':
                    _cancelPayment(payment);
                    break;
                  case 'delete':
                    _deletePayment(payment);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'paid', child: Text('Marcar como paga')),
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
                PopupMenuItem(value: 'delete', child: Text('Apagar')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  String _clientLabel(dynamic clientId) {
    final id = clientId is int ? clientId : int.tryParse(clientId.toString());
    if (id == null) return 'Aluno';
    return _clientNames[id] ?? 'Aluno #$id';
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final clientLabel = _clientLabel(payment['client_id']);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payment['type_of_service']?.toString() ?? 'Fatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aluno: $clientLabel'),
            Text('Valor: ${_formatMoney(payment['cost'])}'),
            Text('Estado: ${_statusLabel(payment['status'])}'),
            Text('Vencimento: ${_formatDate(payment['due_date'])}'),
            if (payment['paid_at'] != null)
              Text('Pago em: ${_formatDate(payment['paid_at'])}'),
            if (_text(payment['payment_method']).isNotEmpty)
              Text('Metodo: ${_text(payment['payment_method'])}'),
            if (_text(payment['notes']).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_text(payment['notes'])),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editPayment(payment);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? payment;
  final String clientLabel;

  const _PaymentSummaryCard({required this.payment, required this.clientLabel});

  @override
  Widget build(BuildContext context) {
    final hasPayment = payment != null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: const Text('Proxima fatura'),
        subtitle: Text(
          hasPayment
              ? '$clientLabel | ${_formatDate(payment!['due_date'])}'
              : 'Sem faturas pendentes',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(hasPayment ? _formatMoney(payment!['cost']) : 'Em dia'),
            Text(
              hasPayment ? _statusLabel(payment!['status']) : 'Sem pendentes',
              style: TextStyle(
                color: hasPayment
                    ? _statusColor(payment!['status'])
                    : Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;

  const _StatusCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

String _statusLabel(dynamic status) {
  switch (status?.toString()) {
    case 'paid':
      return 'Pago';
    case 'overdue':
      return 'Atrasado';
    case 'cancelled':
      return 'Cancelado';
    default:
      return 'Pendente';
  }
}

Color _statusColor(dynamic status) {
  switch (status?.toString()) {
    case 'paid':
      return Colors.green;
    case 'overdue':
      return Colors.redAccent;
    case 'cancelled':
      return Colors.grey;
    default:
      return Colors.orange;
  }
}

String _paymentDateLabel(Map<String, dynamic> payment) {
  final status = payment['status']?.toString();
  if (status == 'paid' && payment['paid_at'] != null) {
    return 'Pago em ${_formatDate(payment['paid_at'])}';
  }
  return 'Vence em ${_formatDate(payment['due_date'])}';
}

String _formatMoney(dynamic value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return 'EUR 0,00';
  return 'EUR ${number.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? 'Sem data';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

String _text(dynamic value) => value?.toString().trim() ?? '';

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
