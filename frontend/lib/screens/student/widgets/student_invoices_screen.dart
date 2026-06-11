import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

class StudentInvoicesScreen extends StatefulWidget {
  final String? token;

  const StudentInvoicesScreen({super.key, required this.token});

  @override
  State<StudentInvoicesScreen> createState() => _StudentInvoicesScreenState();
}

class _StudentInvoicesScreenState extends State<StudentInvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Entre com login para ver as faturas.';
        _isLoading = false;
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

      setState(() {
        if (data is List) {
          _invoices = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          _errorMessage =
              _apiError(data) ?? 'Nao foi possivel carregar faturas.';
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nao foi possivel carregar faturas agora.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? get _nextInvoice {
    final candidates =
        _invoices.where((invoice) {
          final status = invoice['status']?.toString();
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
              icon: const Icon(Icons.refresh, color: StudentTheme.darkText),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          _StatusCard(message: _errorMessage!)
        else if (_invoices.isEmpty)
          const _StatusCard(message: 'Ainda nao existem faturas.')
        else ...[
          _InvoiceSummaryCard(invoice: _nextInvoice),
          const SizedBox(height: 16),
          ..._invoices.map(
            (invoice) => _InvoiceRow(
              invoice: invoice,
              onTap: () => _showInvoiceDetails(invoice),
            ),
          ),
        ],
      ],
    );
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_invoiceTitle(invoice)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor: ${_formatMoney(invoice['cost'])}'),
            Text('Estado: ${_statusLabel(invoice['status'])}'),
            Text('Vencimento: ${_formatDate(invoice['due_date'])}'),
            if (invoice['paid_at'] != null)
              Text('Pago em: ${_formatDate(invoice['paid_at'])}'),
            if (_text(invoice['payment_method']).isNotEmpty)
              Text('Metodo: ${_text(invoice['payment_method'])}'),
            if (_text(invoice['notes']).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_text(invoice['notes'])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? invoice;

  const _InvoiceSummaryCard({required this.invoice});

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
                const Text(
                  'Proxima fatura',
                  style: TextStyle(color: StudentTheme.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  hasInvoice ? _formatMoney(invoice!['cost']) : 'Sem pendentes',
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (hasInvoice)
                  Text(
                    _formatDate(invoice!['due_date']),
                    style: const TextStyle(
                      color: StudentTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            hasInvoice ? _statusLabel(invoice!['status']) : 'Em dia',
            style: TextStyle(
              color: hasInvoice
                  ? _statusColor(invoice!['status'])
                  : StudentTheme.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;

  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: StudentTheme.cardDecoration(),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: StudentTheme.blue.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.attach_money, color: StudentTheme.blue),
        ),
        title: Text(
          _invoiceTitle(invoice),
          style: const TextStyle(
            color: StudentTheme.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          _invoiceDateLabel(invoice),
          style: const TextStyle(color: StudentTheme.mutedText, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatMoney(invoice['cost']),
              style: const TextStyle(
                color: StudentTheme.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _statusLabel(invoice['status']),
              style: TextStyle(
                color: _statusColor(invoice['status']),
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Text(
        message,
        style: const TextStyle(color: StudentTheme.mutedText, fontSize: 15),
      ),
    );
  }
}

String _invoiceTitle(Map<String, dynamic> invoice) {
  final title = _text(invoice['type_of_service']);
  return title.isEmpty ? 'Fatura' : title;
}

String _invoiceDateLabel(Map<String, dynamic> invoice) {
  final status = invoice['status']?.toString();
  if (status == 'paid' && invoice['paid_at'] != null) {
    return 'Pago em ${_formatDate(invoice['paid_at'])}';
  }
  return 'Vence em ${_formatDate(invoice['due_date'])}';
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
      return StudentTheme.blue;
    case 'overdue':
      return Colors.redAccent;
    case 'cancelled':
      return StudentTheme.mutedText;
    default:
      return const Color(0xFFFFD36A);
  }
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
