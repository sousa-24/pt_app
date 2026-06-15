import 'package:flutter/material.dart';

import 'api_service.dart';
import 'client_selector.dart';
import 'l10n/gen/app_localizations.dart';

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

      final l10n = AppLocalizations.of(context)!;
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
          _loadError = _apiError(data) ?? l10n.invoicesLoadError;
        }
        _clientNames = _clientNameMap(contacts, l10n);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = AppLocalizations.of(context)!.invoicesLoadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _createPayment() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedClientId == null) {
      setState(() => _message = l10n.selectStudentMessage);
      return;
    }
    if (_dueDate == null) {
      setState(() => _message = l10n.selectDueDateMessage);
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
        _message = l10n.invoiceCreatedMessage;
        _isSaving = false;
      });
      _loadPayments();
    } else {
      setState(() {
        _message = _apiError(data) ?? l10n.invoiceCreateError;
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
        _message = _apiError(data) ?? AppLocalizations.of(context)!.invoiceUpdateError;
      });
    }
  }

  Future<void> _markAsPaid(Map<String, dynamic> payment) async {
    final l10n = AppLocalizations.of(context)!;
    await _updatePayment(payment, {
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }, l10n.invoiceMarkedPaidMessage);
  }

  Future<void> _cancelPayment(Map<String, dynamic> payment) async {
    final l10n = AppLocalizations.of(context)!;
    await _updatePayment(payment, {'status': 'cancelled'}, l10n.invoiceCancelledMessage);
  }

  Future<void> _deletePayment(Map<String, dynamic> payment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInvoiceTitle),
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
      setState(() => _message = l10n.invoiceDeletedMessage);
      _loadPayments();
    } else {
      setState(() {
        _message = _apiError(data) ?? l10n.invoiceDeleteError;
      });
    }
  }

  Future<void> _editPayment(Map<String, dynamic> payment) async {
    final l10n = AppLocalizations.of(context)!;
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
          title: Text(l10n.editInvoiceTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: serviceController,
                  decoration: InputDecoration(
                    labelText: l10n.serviceLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.amountLabel,
                    prefixText: 'EUR ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: l10n.statusLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'pending', child: Text(l10n.statusPending)),
                    DropdownMenuItem(value: 'paid', child: Text(l10n.statusPaid)),
                    DropdownMenuItem(value: 'overdue', child: Text(l10n.statusOverdue)),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text(l10n.statusCancelled),
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
                        ? l10n.dueDateLabel
                        : _formatDate(dueDate!.toIso8601String(), l10n),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: methodController,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMethodLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
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
        setState(() => _message = l10n.fillValidServiceAndValue);
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
    }, l10n.invoiceUpdatedMessage);

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoicesTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshTooltip,
            onPressed: _isLoading ? null : _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _paymentForm(l10n),
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
            _StatusCard(message: l10n.noInvoicesYet)
          else ...[
            _PaymentSummaryCard(
              payment: _nextPayment,
              clientLabel: _clientLabel(_nextPayment?['client_id'], l10n),
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            ..._payments.map((p) => _paymentCard(p, l10n)),
          ],
        ],
      ),
    );
  }

  Widget _paymentForm(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.newInvoiceTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                decoration: InputDecoration(
                  labelText: l10n.serviceLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  prefixText: 'EUR ',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (amount == null || amount <= 0) return l10n.invalidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _dueDate == null
                      ? l10n.dueDateLabel
                      : _formatDate(_dueDate!.toIso8601String(), l10n),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _methodController,
                decoration: InputDecoration(
                  labelText: l10n.paymentMethodOptionalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.notesOptionalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _createPayment,
                  icon: const Icon(Icons.receipt_long),
                  label: Text(_isSaving ? l10n.creatingLabel : l10n.createInvoiceLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> payment, AppLocalizations l10n) {
    final clientLabel = _clientLabel(payment['client_id'], l10n);
    return Card(
      child: ListTile(
        onTap: () => _showPaymentDetails(payment, l10n),
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(payment['type_of_service']?.toString() ?? l10n.invoiceFallback),
        subtitle: Text('$clientLabel | ${_paymentDateLabel(payment, l10n)}'),
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
                  _statusLabel(payment['status'], l10n),
                  style: TextStyle(
                    color: _statusColor(payment['status']),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: l10n.invoiceActionsTooltip,
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
              itemBuilder: (context) => [
                PopupMenuItem(value: 'paid', child: Text(l10n.markAsPaidAction)),
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(value: 'cancel', child: Text(l10n.cancel)),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  String _clientLabel(dynamic clientId, AppLocalizations l10n) {
    final id = clientId is int ? clientId : int.tryParse(clientId.toString());
    if (id == null) return l10n.accountStudent;
    return _clientNames[id] ?? l10n.studentNumberLabel(id);
  }

  void _showPaymentDetails(Map<String, dynamic> payment, AppLocalizations l10n) {
    final clientLabel = _clientLabel(payment['client_id'], l10n);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payment['type_of_service']?.toString() ?? l10n.invoiceFallback),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.studentDetailLabel(clientLabel)),
            Text(l10n.amountDetailLabel(_formatMoney(payment['cost']))),
            Text(l10n.statusDetailLabel(_statusLabel(payment['status'], l10n))),
            Text(l10n.dueDateDetailLabel(_formatDate(payment['due_date'], l10n))),
            if (payment['paid_at'] != null)
              Text(l10n.paidOnDetailLabel(_formatDate(payment['paid_at'], l10n))),
            if (_text(payment['payment_method']).isNotEmpty)
              Text(l10n.methodDetailLabel(_text(payment['payment_method']))),
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
            label: Text(l10n.edit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? payment;
  final String clientLabel;
  final AppLocalizations l10n;

  const _PaymentSummaryCard({
    required this.payment,
    required this.clientLabel,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasPayment = payment != null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(l10n.nextInvoiceTitle),
        subtitle: Text(
          hasPayment
              ? '$clientLabel | ${_formatDate(payment!['due_date'], l10n)}'
              : l10n.noPendingInvoices,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(hasPayment ? _formatMoney(payment!['cost']) : l10n.upToDate),
            Text(
              hasPayment ? _statusLabel(payment!['status'], l10n) : l10n.noPendingShort,
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

String _statusLabel(dynamic status, AppLocalizations l10n) {
  switch (status?.toString()) {
    case 'paid':
      return l10n.statusPaid;
    case 'overdue':
      return l10n.statusOverdue;
    case 'cancelled':
      return l10n.statusCancelled;
    default:
      return l10n.statusPending;
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

String _paymentDateLabel(Map<String, dynamic> payment, AppLocalizations l10n) {
  final status = payment['status']?.toString();
  if (status == 'paid' && payment['paid_at'] != null) {
    return l10n.paidOnDate(_formatDate(payment['paid_at'], l10n));
  }
  return l10n.dueOnDate(_formatDate(payment['due_date'], l10n));
}

String _formatMoney(dynamic value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return 'EUR 0,00';
  return 'EUR ${number.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatDate(dynamic value, AppLocalizations l10n) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? l10n.noDate;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

String _text(dynamic value) => value?.toString().trim() ?? '';

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
        : l10n.studentNumberLabel(id);
  }
  return result;
}
