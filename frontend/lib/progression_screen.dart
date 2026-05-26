import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Garante que este import está aqui
import 'api_service.dart';

class ProgressionScreen extends StatefulWidget {
  final String token;

  const ProgressionScreen({super.key, required this.token});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  List<dynamic> progression = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProgressionData(); // Apenas uma chamada inicial limpa
  }

  Future<void> _fetchProgressionData() async {
    // Chamada unificada para o endpoint correto do backend Python
    final data = await ApiService.get(context, '/progression/1', widget.token);
    
    if (data != null) {
      setState(() {
        progression = data;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fundo escuro padrão FITPRO
      appBar: AppBar(
        title: const Text('My Progression', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0FD3E)))
          : progression.isEmpty
              ? const Center(child: Text('No progression data yet', style: TextStyle(color: Colors.white54)))
              : ListView( // Mudámos para ListView para poderes fazer scroll entre o gráfico e a lista
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // =========================================================
                    // O GRÁFICO ENTRA AQUI (NO TOPO DO ECRÃ)
                    // =========================================================
                    const Text(
                      "Student Progress",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    StudentProgressChart(progressionData: progression),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      "History Records",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // =========================================================
                    // OS TEUS CARTÕES DE HISTÓRICO ENTRAM AQUI ABAIXO
                    // =========================================================
                    ...progression.map((entry) {
                      return Card(
                        color: const Color(0xFF1C1C1E), // Cartões escuros condizentes
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          title: Text(
                            'Date: ${entry['date']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              if (entry['weight'] != null)
                                Text('Weight: ${entry['weight']} kg', style: const TextStyle(color: Colors.white70)),
                              if (entry['body_fat_percentage'] != null)
                                Text('Body Fat: ${entry['body_fat_percentage']}%', style: const TextStyle(color: Colors.white70)),
                              if (entry['muscle_mass'] != null)
                                Text('Muscle Mass: ${entry['muscle_mass']} kg', style: const TextStyle(color: Colors.white70)),
                              if (entry['notes'] != null)
                                Text('Notes: ${entry['notes']}', style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }
}

// =============================================================================
// WIDGET DO GRÁFICO (REMANEADO COM O NOME DA CLASSE CORRETO: FlSpot)
// =============================================================================
class StudentProgressChart extends StatelessWidget {
  final List<dynamic> progressionData;

  const StudentProgressChart({Key? key, required this.progressionData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (progressionData.isEmpty) {
      return const Center(
        child: Text("Nenhum registo de progresso encontrado.", style: TextStyle(color: Colors.white54)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // 1. Linha do Peso (Verde Neon)
              LineChartBarData(
                spots: progressionData.asMap().entries.map((e) {
                  final weight = e.value['weight'] ?? 0.0;
                  return FlSpot(e.key.toDouble(), weight.toDouble()); // Corrigido para FlSpot
                }).toList(),
                isCurved: true,
                color: const Color(0xFFD0FD3E),
                barWidth: 3,
              ),
              // 2. Linha da Massa Muscular (Branco)
              LineChartBarData(
                spots: progressionData.asMap().entries.map((e) {
                  final muscle = e.value['muscle_mass'] ?? 0.0;
                  return FlSpot(e.key.toDouble(), muscle.toDouble()); // Corrigido para FlSpot
                }).toList(),
                isCurved: true,
                color: Colors.white,
                barWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}