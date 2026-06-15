import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'l10n/gen/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    try {
      final data = await ApiService.get(
        context,
        '/api/v1/profile/me',
        widget.token,
      );
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
          _errorMessage = AppLocalizations.of(context)!.profileLoadError;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.profileLoadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPicture() async {
    if (_isUploading) return;

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
        widget.token,
        picked,
      );
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      if (data is Map<String, dynamic> && data['profile_picture_url'] != null) {
        setState(() {
          _profilePictureUrl = data['profile_picture_url'] as String?;
        });
      } else {
        final message = data is Map<String, dynamic>
            ? _text(data['detail'], l10n.profilePictureUpdateError)
            : l10n.profilePictureUpdateError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profilePictureUpdateError)),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfileMenu)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(child: _avatar()),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadPicture,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      _isUploading ? l10n.uploadingLabel : l10n.changePictureAction,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(l10n.nameLabel),
                          subtitle: Text(_name),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: Text(l10n.emailLabel),
                          subtitle: Text(_email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(l10n.accountTypeLabel),
                          subtitle: Text(
                            _role == 'trainer' ? l10n.accountTrainer : l10n.accountStudent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _avatar() {
    return InkWell(
      borderRadius: BorderRadius.circular(58),
      onTap: _isUploading ? null : _pickAndUploadPicture,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundImage: _profilePictureUrl != null
                ? NetworkImage(_profilePictureUrl!)
                : null,
            child: _profilePictureUrl == null
                ? const Icon(Icons.person, size: 52)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined, size: 19),
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
