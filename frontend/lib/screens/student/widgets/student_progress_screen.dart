import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

class StudentProgressScreen extends StatefulWidget {
  final String? token;

  const StudentProgressScreen({
    super.key,
    required this.token,
  });

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _progress = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await ApiService.get(
        context,
        '/progression/',
        token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        if (data is List) {
          _progress = List<Map<String, dynamic>>.from(data);
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Nao foi possivel carregar os dados de progresso agora.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O Meu Progresso',
          style: TextStyle(
            color: StudentTheme.darkText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: StudentTheme.cardDecoration(),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: StudentTheme.mutedText,
                fontSize: 15,
              ),
            ),
          )
        else if (_progress.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: StudentTheme.cardDecoration(),
            child: const Text(
              'Ainda nao existem dados de progressao registados.',
              style: TextStyle(
                color: StudentTheme.mutedText,
                fontSize: 15,
              ),
            ),
          )
        else ...[
          _LatestProgressCard(entry: _progress.last),
          const SizedBox(height: 14),
          ..._progress.reversed.map((entry) => _ProgressHistoryCard(entry: entry)),
        ],
      ],
    );
  }
}

class _LatestProgressCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _LatestProgressCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ultima avaliacao',
            style: TextStyle(
              color: StudentTheme.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Peso',
                  value: _formatNumber(entry['weight'], 'kg'),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Massa gorda',
                  value: _formatNumber(entry['body_fat_percentage'], '%'),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Massa muscular',
                  value: _formatNumber(entry['muscle_mass'], 'kg'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressHistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _ProgressHistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(entry['date']),
            style: const TextStyle(
              color: StudentTheme.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Peso: ${_formatNumber(entry['weight'], 'kg')}  |  Massa gorda: ${_formatNumber(entry['body_fat_percentage'], '%')}  |  Massa muscular: ${_formatNumber(entry['muscle_mass'], 'kg')}',
            style: const TextStyle(
              color: StudentTheme.mutedText,
              fontSize: 13,
            ),
          ),
          if (entry['notes'] != null && entry['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry['notes'].toString(),
              style: const TextStyle(
                color: StudentTheme.darkText,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: StudentTheme.blue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: StudentTheme.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

String _formatNumber(dynamic value, String suffix) {
  if (value == null) return '-';
  final number = value is num ? value : num.tryParse(value.toString());
  if (number == null) return '-';
  return '${number.toStringAsFixed(1)} $suffix';
}

String _formatDate(dynamic value) {
  if (value == null) return 'Sem data';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  return '$day/$month/$year';
}
