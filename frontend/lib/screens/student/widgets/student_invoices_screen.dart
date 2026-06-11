import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

class StudentInvoicesScreen extends StatefulWidget {
  final String? token;

  const StudentInvoicesScreen({super.key, this.token});

  @override
  State<StudentInvoicesScreen> createState() => _StudentInvoicesScreenState();
}

class _StudentInvoicesScreenState extends State<StudentInvoicesScreen> {
  List<_StudentInvoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void didUpdateWidget(covariant StudentInvoicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _loadInvoices();
    }
  }

  Future<void> _loadInvoices() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Entre com login para ver as faturas.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/payments/',
        token,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (data is! List) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nao foi possivel carregar as faturas.';
        });
        return;
      }

      final invoices = data
          .map(_StudentInvoice.fromApi)
          .whereType<_StudentInvoice>()
          .toList()
        ..sort(_sortInvoices);

      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nao foi possivel carregar as faturas agora.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextInvoice = _nextInvoice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Faturas',
                style: TextStyle(
                  color: StudentTheme.darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _isLoading ? null : _loadInvoices,
              icon: const Icon(Icons.refresh, color: StudentTheme.blue),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InvoiceSummaryCard(invoice: nextInvoice, isLoading: _isLoading),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          _StatusCard(message: _errorMessage!)
        else if (_invoices.isEmpty)
          const _StatusCard(message: 'Quando a personal emitir uma fatura, ela aparece aqui.')
        else
          ..._invoices.map(
            (invoice) => _InvoiceRow(
              invoice: invoice,
              onTap: () => _showInvoiceDetails(invoice),
            ),
          ),
      ],
    );
  }

  _StudentInvoice? get _nextInvoice {
    for (final invoice in _invoices) {
      if (invoice.status == 'pending' || invoice.status == 'overdue') {
        return invoice;
      }
    }
    return null;
  }

  void _showInvoiceDetails(_StudentInvoice invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: StudentTheme.navy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: invoice.statusColor.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: invoice.statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.title,
                            style: const TextStyle(
                              color: StudentTheme.darkText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.statusLabel,
                            style: TextStyle(
                              color: invoice.statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InvoiceDetailRow(
                  icon: Icons.euro_outlined,
                  label: 'Valor',
                  value: invoice.formattedAmount,
                ),
                _InvoiceDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Vencimento',
                  value: invoice.dueDateLabel,
                ),
                if (invoice.paidAt != null)
                  _InvoiceDetailRow(
                    icon: Icons.check_circle_outline,
                    label: 'Pago em',
                    value: _formatDate(invoice.paidAt!),
                  ),
                _InvoiceDetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Metodo de pagamento',
                  value: invoice.paymentMethod?.trim().isNotEmpty == true
                      ? invoice.paymentMethod!.trim()
                      : 'Ainda nao definido',
                ),
                _InvoiceDetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Notas',
                  value: invoice.notes?.trim().isNotEmpty == true
                      ? invoice.notes!.trim()
                      : 'Sem notas para esta fatura.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static int _sortInvoices(_StudentInvoice a, _StudentInvoice b) {
    final statusComparison =
        _statusPriority(a.status).compareTo(_statusPriority(b.status));
    if (statusComparison != 0) return statusComparison;
    return a.dueDate.compareTo(b.dueDate);
  }

  static int _statusPriority(String status) {
    switch (status) {
      case 'overdue':
        return 0;
      case 'pending':
        return 1;
      case 'paid':
        return 2;
      case 'cancelled':
        return 3;
      default:
        return 4;
    }
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final _StudentInvoice? invoice;
  final bool isLoading;

  const _InvoiceSummaryCard({required this.invoice, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final hasInvoice = invoice != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: StudentTheme.blue,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasInvoice || isLoading
                      ? 'Proxima fatura'
                      : 'Faturas em aberto',
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? 'A carregar...'
                      : hasInvoice
                          ? invoice!.formattedAmount
                          : 'Tudo em dia',
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (hasInvoice) ...[
                  const SizedBox(height: 3),
                  Text(
                    invoice!.dueDateLabel,
                    style: const TextStyle(
                      color: StudentTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            isLoading
                ? ''
                : hasInvoice
                    ? invoice!.statusLabel
                    : 'Sem faturas',
            style: TextStyle(
              color: hasInvoice ? invoice!.statusColor : StudentTheme.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final _StudentInvoice invoice;
  final VoidCallback onTap;

  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: StudentTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: invoice.statusColor.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                invoice.statusIcon,
                color: invoice.statusColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.title,
                    style: const TextStyle(
                      color: StudentTheme.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.dateLine,
                    style: const TextStyle(
                      color: StudentTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  invoice.formattedAmount,
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.statusLabel,
                  style: TextStyle(
                    color: invoice.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InvoiceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: StudentTheme.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;

  const _StatusCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Text(
        message,
        style: const TextStyle(color: StudentTheme.mutedText, fontSize: 14),
      ),
    );
  }
}

class _StudentInvoice {
  final int id;
  final String title;
  final double amount;
  final String status;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? notes;

  const _StudentInvoice({
    required this.id,
    required this.title,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.notes,
  });

  static _StudentInvoice? fromApi(dynamic value) {
    final data = value is Map<String, dynamic> ? value : null;
    if (data == null) return null;

    final dueDate = DateTime.tryParse(data['due_date']?.toString() ?? '');
    if (dueDate == null) return null;

    return _StudentInvoice(
      id: _intValue(data['id']),
      title: _text(data['type_of_service'], 'Fatura'),
      amount: _doubleValue(data['cost']),
      status: _normalizedStatus(_text(data['status'], 'pending'), dueDate),
      dueDate: dueDate,
      paidAt: DateTime.tryParse(data['paid_at']?.toString() ?? ''),
      paymentMethod: data['payment_method']?.toString(),
      notes: data['notes']?.toString(),
    );
  }

  String get formattedAmount =>
      'EUR ${amount.toStringAsFixed(2).replaceAll('.', ',')}';

  String get dueDateLabel => 'Vence em ${_formatDate(dueDate)}';

  String get dateLine {
    if (status == 'paid' && paidAt != null) {
      return 'Pago em ${_formatDate(paidAt!)}';
    }
    return dueDateLabel;
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'paid':
        return 'Pago';
      case 'overdue':
        return 'Atrasado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'paid':
        return StudentTheme.blue;
      case 'overdue':
        return const Color(0xFFFF7185);
      case 'cancelled':
        return StudentTheme.mutedText;
      case 'pending':
      default:
        return const Color(0xFFFFD36A);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.receipt_long_outlined;
    }
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _text(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String _normalizedStatus(String status, DateTime dueDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (status == 'pending' && dueDateOnly.isBefore(todayOnly)) {
      return 'overdue';
    }

    return status;
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}
