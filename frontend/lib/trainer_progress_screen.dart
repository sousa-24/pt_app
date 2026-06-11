import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'client_selector.dart';

class TrainerProgressScreen extends StatefulWidget {
  final String token;

  const TrainerProgressScreen({super.key, required this.token});

  @override
  State<TrainerProgressScreen> createState() => _TrainerProgressScreenState();
}

class _TrainerProgressScreenState extends State<TrainerProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedClientId;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _progress = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final clientId = _selectedClientId;
    if (clientId == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final data = await ApiService.get(
        context,
        '/api/v1/progression/$clientId',
        widget.token,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      setState(() {
        _progress = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Nao foi possivel carregar o progresso deste aluno.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    if (_selectedClientId == null) {
      setState(() => _message = 'Seleciona um aluno primeiro.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final data =
        await ApiService.post(context, '/api/v1/progression/', widget.token, {
          'client_id': _selectedClientId,
          'date': _selectedDate.toIso8601String(),
          'weight': _parseNumber(_weightController.text),
          'body_fat_percentage': _parseNumber(_bodyFatController.text),
          'muscle_mass': _parseNumber(_muscleMassController.text),
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        });
    if (!mounted) return;

    if (data is Map && data['id'] != null) {
      _weightController.clear();
      _bodyFatController.clear();
      _muscleMassController.clear();
      _notesController.clear();
      setState(() {
        _message = 'Progresso registado com sucesso.';
        _isSaving = false;
      });
      _loadProgress();
    } else {
      setState(() {
        _message = _apiError(data) ?? 'Nao foi possivel guardar o progresso.';
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso dos Alunos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClientSelector(
            token: widget.token,
            selectedClientId: _selectedClientId,
            onChanged: (clientId) {
              setState(() {
                _selectedClientId = clientId;
                _progress = [];
              });
              _loadProgress();
            },
          ),
          const SizedBox(height: 16),
          _progressForm(),
          const SizedBox(height: 18),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_message!),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedClientId == null)
            const Center(
              child: Text('Seleciona um aluno para ver o progresso.'),
            )
          else if (_progress.isEmpty)
            const Center(child: Text('Ainda nao existem registos.'))
          else ...[
            SizedBox(height: 280, child: _ProgressChart(data: _progress)),
            const SizedBox(height: 16),
            ..._progress.reversed.map(_progressCard),
          ],
        ],
      ),
    );
  }

  Widget _progressForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registar avaliação física',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_formatDate(_selectedDate.toIso8601String())),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(_weightController, 'Peso', 'kg', true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numberField(
                      _bodyFatController,
                      'Massa gorda',
                      '%',
                      false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _numberField(
                _muscleMassController,
                'Massa muscular',
                'kg',
                false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProgress,
                  icon: const Icon(Icons.add_chart),
                  label: Text(_isSaving ? 'A guardar...' : 'Guardar progresso'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String suffix,
    bool requiredField,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredField && text.isEmpty) return 'Obrigatorio';
        if (text.isNotEmpty && _parseNumber(text) == null) {
          return 'Valor invalido';
        }
        return null;
      },
    );
  }

  Widget _progressCard(Map<String, dynamic> entry) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text(_formatDate(entry['date'])),
        subtitle: Text(
          'Peso: ${_formatNumber(entry['weight'], 'kg')} | Massa gorda: ${_formatNumber(entry['body_fat_percentage'], '%')} | Massa muscular: ${_formatNumber(entry['muscle_mass'], 'kg')}',
        ),
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _ProgressChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              _line('weight', Theme.of(context).colorScheme.primary, 3),
              _line('muscle_mass', Colors.white70, 2),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _line(String key, Color color, double width) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), _readNumber(entry.value[key]));
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: width,
    );
  }
}

double? _parseNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

double _readNumber(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatNumber(dynamic value, String suffix) {
  final number = _readNumber(value);
  if (number == 0) return '-';
  return '${number.toStringAsFixed(1)} $suffix';
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? 'Sem data';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

String? _apiError(dynamic data) {
  if (data is Map && data['detail'] != null) return data['detail'].toString();
  return null;
}
