import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

enum _ProfileView { overview, data, password }

class StudentProfileCard extends StatefulWidget {
  final String? token;
  final String name;
  final String email;
  final void Function(Map<String, dynamic> user) onProfileUpdated;
  final void Function(bool isDetailView)? onDetailViewChanged;
  final int backRequest;

  const StudentProfileCard({
    super.key,
    required this.token,
    required this.name,
    required this.email,
    required this.onProfileUpdated,
    this.onDetailViewChanged,
    this.backRequest = 0,
  });

  @override
  State<StudentProfileCard> createState() => _StudentProfileCardState();
}

class _StudentProfileCardState extends State<StudentProfileCard> {
  final _dataFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ProfileView _view = _ProfileView.overview;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant StudentProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.email != widget.email) {
      _syncControllers();
    }
    if (oldWidget.backRequest != widget.backRequest) {
      _view = _ProfileView.overview;
      _message = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _nameController.text = widget.name;
    _emailController.text = widget.email;
  }

  Future<void> _saveData() async {
    final token = widget.token;
    if (token == null ||
        token.isEmpty ||
        !_dataFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    final result = await ApiService.patch(
      context,
      '/api/v1/profile/me',
      token,
      {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result is Map<String, dynamic> && result['id'] != null) {
      widget.onProfileUpdated(result);
      _goOverview(message: 'Dados atualizados com sucesso.');
    } else {
      setState(() {
        _message = _errorMessage(result, 'Nao foi possivel atualizar os dados.');
      });
    }
  }

  Future<void> _savePassword() async {
    final token = widget.token;
    if (token == null ||
        token.isEmpty ||
        !_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    final result = await ApiService.patch(
      context,
      '/api/v1/profile/me',
      token,
      {'password': _passwordController.text.trim()},
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result is Map<String, dynamic> && result['id'] != null) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      widget.onProfileUpdated(result);
      _goOverview(message: 'Senha atualizada com sucesso.');
    } else {
      setState(() {
        _message = _errorMessage(result, 'Nao foi possivel atualizar a senha.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(),
          const SizedBox(height: 18),
          if (_view == _ProfileView.overview) _overview(),
          if (_view == _ProfileView.data) _dataForm(),
          if (_view == _ProfileView.password) _passwordForm(),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Text(
              _message!,
              style: const TextStyle(
                color: StudentTheme.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _titleForView(),
            style: const TextStyle(
              color: StudentTheme.darkText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _overview() {
    return Column(
      children: [
        _optionTile(
          title: 'Seus dados',
          subtitle: '${widget.name} • ${widget.email}',
          icon: Icons.person_outline,
          onTap: () => _setView(_ProfileView.data),
        ),
        const SizedBox(height: 12),
        _optionTile(
          title: 'Atualizar senha',
          subtitle: 'Alterar senha de acesso',
          icon: Icons.lock_outline,
          onTap: () => _setView(_ProfileView.password),
        ),
      ],
    );
  }

  Widget _dataForm() {
    return Form(
      key: _dataFormKey,
      child: Column(
        children: [
          _textField(
            controller: _nameController,
            label: 'Nome',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty || !email.contains('@')) {
                return 'Informe um email valido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _primaryButton(
            label: _saving ? 'A guardar...' : 'Guardar dados',
            icon: Icons.save_outlined,
            onPressed: _saving ? null : _saveData,
          ),
        ],
      ),
    );
  }

  Widget _passwordForm() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Digite e confirme a nova senha de acesso.',
            style: TextStyle(color: StudentTheme.mutedText),
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _passwordController,
            label: 'Nova senha',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().length < 6) {
                return 'Use pelo menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _confirmPasswordController,
            label: 'Confirmar nova senha',
            icon: Icons.lock_reset,
            obscureText: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'As senhas nao coincidem.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _primaryButton(
            label: _saving ? 'A guardar...' : 'Guardar nova senha',
            icon: Icons.save_outlined,
            onPressed: _saving ? null : _savePassword,
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A3D)),
        ),
        child: Row(
          children: [
            Icon(icon, color: StudentTheme.blue),
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
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: StudentTheme.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: StudentTheme.mutedText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: StudentTheme.darkText),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: StudentTheme.blue),
        labelStyle: const TextStyle(color: StudentTheme.mutedText),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
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
          borderSide: const BorderSide(color: Color(0xFFFF7185)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF7185)),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1C1C1E),
                ),
              )
            : Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: StudentTheme.blue,
          foregroundColor: const Color(0xFF1C1C1E),
        ),
      ),
    );
  }

  String _titleForView() {
    switch (_view) {
      case _ProfileView.data:
        return 'Seus dados';
      case _ProfileView.password:
        return 'Atualizar senha';
      case _ProfileView.overview:
        return 'Editar perfil';
    }
  }

  void _setView(_ProfileView view) {
    setState(() {
      _view = view;
      _message = null;
    });
    widget.onDetailViewChanged?.call(view != _ProfileView.overview);
  }

  void _goOverview({String? message}) {
    setState(() {
      _view = _ProfileView.overview;
      _message = message;
    });
    widget.onDetailViewChanged?.call(false);
  }

  String _errorMessage(dynamic result, String fallback) {
    if (result is Map<String, dynamic>) {
      final detail = result['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return fallback;
  }
}
