import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentInvoicesScreen extends StatelessWidget {
  const StudentInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faturas',
          style: TextStyle(
            color: StudentTheme.darkText,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        _InvoiceSummaryCard(),
        const SizedBox(height: 16),
        _InvoiceRow(
          title: 'Plano mensal - Maio',
          date: 'Vence em 25/05',
          value: 'EUR 45,00',
          status: 'Pendente',
          isPaid: false,
        ),
        _InvoiceRow(
          title: 'Plano mensal - Abril',
          date: 'Pago em 20/04',
          value: 'EUR 45,00',
          status: 'Pago',
          isPaid: true,
        ),
        _InvoiceRow(
          title: 'Treino extra',
          date: 'Pago em 12/04',
          value: 'EUR 15,00',
          status: 'Pago',
          isPaid: true,
        ),
      ],
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: const Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: StudentTheme.blue,
            size: 34,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proxima fatura',
                  style: TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'EUR 45,00',
                  style: TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Pendente',
            style: TextStyle(
              color: Color(0xFFFFD36A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String title;
  final String date;
  final String value;
  final String status;
  final bool isPaid;

  const _InvoiceRow({
    required this.title,
    required this.date,
    required this.value,
    required this.status,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: StudentTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: StudentTheme.blue.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attach_money,
              color: StudentTheme.blue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: StudentTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: StudentTheme.darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: isPaid ? StudentTheme.blue : const Color(0xFFFFD36A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
