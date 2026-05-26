import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

class StudentProgressScreen extends StatefulWidget {
  final String? token;

  const StudentProgressScreen({super.key, required this.token});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, dynamic>> _progress = [];
  DateTime _selectedDate = DateTime.now();

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
        '/api/v1/progression/',
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

  Future<void> _saveProgress() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final data =
          await ApiService.post(context, '/api/v1/progression/', token, {
            'date': _selectedDate.toIso8601String(),
            'weight': _parseNumber(_weightController.text),
            'body_fat_percentage': _parseNumber(_bodyFatController.text),
            'muscle_mass': _parseNumber(_muscleMassController.text),
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          }).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      if (data is Map<String, dynamic> && data['id'] != null) {
        _weightController.clear();
        _bodyFatController.clear();
        _muscleMassController.clear();
        _notesController.clear();

        setState(() {
          _successMessage = 'Progresso registado com sucesso.';
          _isSaving = false;
        });
        await _loadProgress();
      } else {
        setState(() {
          _errorMessage = data is Map && data['detail'] != null
              ? data['detail'].toString()
              : 'Nao foi possivel guardar o progresso.';
          _isSaving = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Nao foi possivel guardar o progresso agora.';
        _isSaving = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _notesController.dispose();
    super.dispose();
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
        _ProgressFormCard(
          formKey: _formKey,
          selectedDate: _selectedDate,
          weightController: _weightController,
          bodyFatController: _bodyFatController,
          muscleMassController: _muscleMassController,
          notesController: _notesController,
          isSaving: _isSaving,
          successMessage: _successMessage,
          onPickDate: _pickDate,
          onSubmit: _saveProgress,
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
              style: TextStyle(color: StudentTheme.mutedText, fontSize: 15),
            ),
          )
        else ...[
          _LatestProgressCard(entry: _progress.last),
          const SizedBox(height: 14),
          ..._progress.reversed.map(
            (entry) => _ProgressHistoryCard(entry: entry),
          ),
        ],
      ],
    );
  }
}

class _ProgressFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DateTime selectedDate;
  final TextEditingController weightController;
  final TextEditingController bodyFatController;
  final TextEditingController muscleMassController;
  final TextEditingController notesController;
  final bool isSaving;
  final String? successMessage;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  const _ProgressFormCard({
    required this.formKey,
    required this.selectedDate,
    required this.weightController,
    required this.bodyFatController,
    required this.muscleMassController,
    required this.notesController,
    required this.isSaving,
    required this.successMessage,
    required this.onPickDate,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registar progresso',
              style: TextStyle(
                color: StudentTheme.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onPickDate,
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Data',
                  icon: Icons.calendar_today_outlined,
                ),
                child: Text(
                  _formatDate(selectedDate.toIso8601String()),
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: weightController,
                    label: 'Peso',
                    suffix: 'kg',
                    requiredField: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberField(
                    controller: bodyFatController,
                    label: 'Massa gorda',
                    suffix: '%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: muscleMassController,
              label: 'Massa muscular',
              suffix: 'kg',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: StudentTheme.darkText),
              decoration: _inputDecoration(
                label: 'Notas',
                icon: Icons.notes_outlined,
              ),
            ),
            if (successMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                successMessage!,
                style: const TextStyle(
                  color: StudentTheme.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_chart),
                label: Text(isSaving ? 'A guardar...' : 'Guardar progresso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool requiredField;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: StudentTheme.darkText),
      decoration: _inputDecoration(label: label, suffix: suffix),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredField && text.isEmpty) {
          return 'Obrigatorio';
        }
        if (text.isNotEmpty && _parseNumber(text) == null) {
          return 'Valor invalido';
        }
        return null;
      },
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
            style: TextStyle(color: StudentTheme.mutedText, fontSize: 13),
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
            style: const TextStyle(color: StudentTheme.mutedText, fontSize: 13),
          ),
          if (entry['notes'] != null &&
              entry['notes'].toString().isNotEmpty) ...[
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

  const _Metric({required this.label, required this.value});

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
          style: const TextStyle(color: StudentTheme.mutedText, fontSize: 12),
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

double? _parseNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

InputDecoration _inputDecoration({
  required String label,
  IconData? icon,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    suffixText: suffix,
    prefixIcon: icon == null ? null : Icon(icon),
    labelStyle: const TextStyle(color: StudentTheme.mutedText),
    suffixStyle: const TextStyle(color: StudentTheme.mutedText),
    prefixIconColor: StudentTheme.mutedText,
    filled: true,
    fillColor: const Color(0xFF242426),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF3A3A3D)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: StudentTheme.blue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}
