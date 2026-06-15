import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api_service.dart';
import '../student_theme.dart';

class StudentProfileCard extends StatefulWidget {
  final String? token;

  const StudentProfileCard({super.key, this.token});

  @override
  State<StudentProfileCard> createState() => _StudentProfileCardState();
}

class _StudentProfileCardState extends State<StudentProfileCard> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  String _name = '';
  String _email = '';
  String _role = '';
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = widget.token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sessao invalida.';
      });
      return;
    }

    try {
      final data = await ApiService.get(context, '/api/v1/profile/me', token);
      if (!mounted) return;

      if (data is Map<String, dynamic> && data['detail'] == null) {
        setState(() {
          _name = _text(data['name'], '');
          _email = _text(data['email'], '');
          _role = _text(data['role'], '');
          _profilePictureUrl = data['profile_picture_url'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Nao foi possivel carregar o perfil.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nao foi possivel carregar o perfil.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPicture() async {
    final token = widget.token;
    if (token == null || _isUploading) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);

    try {
      final data = await ApiService.uploadProfilePicture(
        context,
        token,
        picked,
      );
      if (!mounted) return;

      if (data is Map<String, dynamic> && data['profile_picture_url'] != null) {
        setState(() {
          _profilePictureUrl = data['profile_picture_url'] as String?;
        });
      } else {
        final message = data is Map<String, dynamic>
            ? _text(data['detail'], 'Nao foi possivel atualizar a foto.')
            : 'Nao foi possivel atualizar a foto.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel atualizar a foto.')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
          const Text(
            'Perfil do aluno',
            style: TextStyle(
              color: StudentTheme.darkText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: StudentTheme.blue),
              ),
            )
          else if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: StudentTheme.mutedText),
            )
          else ...[
            Center(child: _avatar()),
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.person_outline, label: 'Nome', value: _name),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: _email),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Tipo',
              value: _role == 'trainer' ? 'Personal' : 'Aluno',
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatar() {
    return InkWell(
      borderRadius: BorderRadius.circular(58),
      onTap: _pickAndUploadPicture,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: StudentTheme.blue, width: 4),
              color: const Color(0xFF2C2C2E),
              image: _profilePictureUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_profilePictureUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profilePictureUrl == null
                ? const Icon(
                    Icons.person,
                    color: StudentTheme.mutedText,
                    size: 62,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: StudentTheme.blue,
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.black,
                      size: 19,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _text(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, color: StudentTheme.blue),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: StudentTheme.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: StudentTheme.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
