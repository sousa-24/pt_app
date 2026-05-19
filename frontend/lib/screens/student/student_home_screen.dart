import 'package:flutter/material.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  static const Color blue = Color(0xFF0A73FF);
  static const Color darkText = Color(0xFF07164A);
  static const Color lightBg = Color(0xFFFDFDFD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      bottomNavigationBar: _bottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 22),
              _statsRow(),
              const SizedBox(height: 26),
              _sectionTitle('TREINO DO DIA', action: 'Ver tudo'),
              const SizedBox(height: 10),
              _workoutCard(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _waterCard()),
                  const SizedBox(width: 14),
                  Expanded(child: _challengeCard()),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'AÇÕES RÁPIDAS',
                style: TextStyle(
                  color: darkText,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _quickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, Alex! 👋',
                style: TextStyle(
                  color: darkText,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Pronto para atingir os teus objetivos hoje?',
                style: TextStyle(
                  color: Color(0xFF667096),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            const Icon(Icons.notifications_none, color: darkText, size: 32),
            Positioned(
              right: 0,
              top: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.local_fire_department,
            '320',
            'Calorias',
            blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            Icons.directions_run,
            '7,254',
            'Passos',
            Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            Icons.bolt,
            '45',
            'Min. ativos',
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            Icons.emoji_events,
            '12',
            'Dias seguidos',
            Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667096),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          Row(
            children: [
              Text(
                action,
                style: const TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, color: blue, size: 13),
            ],
          ),
      ],
    );
  }

  Widget _workoutCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _exerciseItem(
            imageUrl:
                'https://images.unsplash.com/photo-1599058917765-a780eda07a3e?w=400',
            title: '1. Agachamentos',
            subtitle: '3 Séries  •  15 Repetições',
          ),
          const Divider(height: 18),
          _exerciseItem(
            imageUrl:
                'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=400',
            title: '2. Supino',
            subtitle: '3 Séries  •  12 Repetições',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.fitness_center),
              label: const Text(
                'Começar treino',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseItem({
    required String imageUrl,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            width: 135,
            height: 86,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF667096),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Text('🏋️‍♂️  🦵', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            color: blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _waterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÁGUA DIÁRIA',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: const [
                SizedBox(
                  width: 95,
                  height: 95,
                  child: CircularProgressIndicator(
                    value: 0.72,
                    strokeWidth: 8,
                    backgroundColor: Color(0xFFDCEBFF),
                    valueColor: AlwaysStoppedAnimation<Color>(blue),
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.water_drop, color: blue),
                    Text(
                      '1.8 L',
                      style: TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'de 2.5 L',
                      style: TextStyle(
                        color: Color(0xFF667096),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '💧 💧 💧 💧 ◻️',
              style: TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Muito bem! Continua a beber água 💧',
              style: TextStyle(
                color: Color(0xFF667096),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _challengeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESAFIO ATUAL',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 126,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFFB000)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30 DIAS\nPERDA DE PESO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Mantém a consistência.\nVê a mudança!',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                Spacer(),
                Text(
                  'Dia 12 de 30',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.4,
                  minHeight: 7,
                  backgroundColor: Color(0xFFECEFF5),
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '40%',
                style: TextStyle(
                  color: darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(child: _action(Icons.calendar_month, 'Plano', blue)),
        const SizedBox(width: 10),
        Expanded(child: _action(Icons.restaurant_menu, 'Nutrição', Colors.deepOrange)),
        const SizedBox(width: 10),
        Expanded(child: _action(Icons.self_improvement, 'Alongar', Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _action(Icons.bar_chart, 'Progresso', Colors.deepPurple)),
        const SizedBox(width: 10),
        Expanded(child: _action(Icons.favorite_border, 'Saúde', Colors.redAccent)),
      ],
    );
  }

  Widget _action(IconData icon, String label, Color color) {
    return Container(
      height: 66,
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: darkText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 74,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: 'Início', active: true),
          _NavItem(icon: Icons.fitness_center, label: 'Treinos'),
          CircleAvatar(
            radius: 23,
            backgroundColor: blue,
            child: Icon(Icons.add, color: Colors.white, size: 30),
          ),
          _NavItem(icon: Icons.emoji_events_outlined, label: 'Desafios'),
          _NavItem(icon: Icons.person_outline, label: 'Perfil'),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEFF2F8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color blue = Color(0xFF0A73FF);
    const Color darkText = Color(0xFF07164A);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? blue : const Color(0xFF8A91A8)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? blue : darkText.withOpacity(0.55),
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}