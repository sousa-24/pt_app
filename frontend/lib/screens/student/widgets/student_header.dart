import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import '../student_theme.dart';
import '../../../api_service.dart';
import '../../../l10n/gen/app_localizations.dart';

class StudentHeader extends StatefulWidget {
  final String studentName;
  final String? profilePictureUrl;
  final String? token;
  final void Function(String type)? onNotificationTap;
  final VoidCallback? onProfilePictureTap;
  final bool isUploadingProfilePicture;
  final VoidCallback? onBack;
  final bool showGreeting;
  final bool showEditPhotoAction;

  const StudentHeader({
    super.key,
    required this.studentName,
    this.profilePictureUrl,
    this.token,
    this.onNotificationTap,
    this.onProfilePictureTap,
    this.isUploadingProfilePicture = false,
    this.onBack,
    this.showGreeting = true,
    this.showEditPhotoAction = false,
  });

  @override
  State<StudentHeader> createState() => _StudentHeaderState();
}

class _StudentHeaderState extends State<StudentHeader> {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = false;
  WebSocketChannel? _ws;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _ws?.sink.close();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    try {
      final resp = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/v1/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200 || !mounted) return;
      final userId = jsonDecode(resp.body)['id'];
      if (userId == null) return;

      final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
      _ws = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/$userId?token=$token'),
      );
      _ws!.stream.listen((raw) {
        try {
          final data = jsonDecode(raw.toString());
          if (data is Map && data['type'] == 'new_notification') {
            _fetchUnreadCount();
          }
        } catch (_) {}
      }, onError: (_) {}, onDone: () {});
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    try {
      final resp = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/v1/notifications/unread_count/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _unreadCount = data['count'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/v1/notifications/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() => _notifications = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    try {
      await http.put(
        Uri.parse('${ApiService.baseUrl}/api/v1/notifications/read_all/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      setState(() {
        _unreadCount = 0;
        for (final n in _notifications) {
          n['read'] = true;
        }
      });
    } catch (_) {}
  }

  void _openNotifications() {
    _fetchNotifications().then((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (_) => _NotificationPanel(
          notifications: _notifications,
          loading: _loading,
          onMarkAllRead: () {
            _markAllRead();
            Navigator.pop(context);
          },
          onNotificationTap: (type) {
            Navigator.pop(context);
            widget.onNotificationTap?.call(type);
          },
        ),
      );
      _markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
      decoration: const BoxDecoration(
        color: StudentTheme.darkNavy,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: StudentTheme.blue,
                      size: 44,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: widget.onBack == null
                      ? const SizedBox.shrink()
                      : TextButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                          ),
                          label: const Text('Voltar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton.filled(
                        onPressed: _openNotifications,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2E),
                          foregroundColor: StudentTheme.blue,
                        ),
                        icon: Icon(
                          _unreadCount > 0
                              ? Icons.notifications
                              : Icons.notifications_none,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7185),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _unreadCount > 99 ? '99+' : '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: widget.onProfilePictureTap,
              child: Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: StudentTheme.blue, width: 4),
                  color: const Color(0xFF2C2C2E),
                ),
                child: ClipOval(
                  child: _profilePicture(),
                ),
              ),
            ),
            if (widget.showEditPhotoAction) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: widget.isUploadingProfilePicture
                    ? null
                    : widget.onProfilePictureTap,
                icon: widget.isUploadingProfilePicture
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: StudentTheme.blue,
                        ),
                      )
                    : const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(
                  widget.isUploadingProfilePicture
                      ? 'A enviar...'
                      : 'Editar foto',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: StudentTheme.blue,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
            if (widget.showGreeting) ...[
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_greetingForNow()}, ${_firstName(widget.studentName, l10n)}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _firstName(String name, AppLocalizations l10n) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return l10n.accountStudent;
    return trimmed.split(' ').first;
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _profilePicture() {
    final url = _avatarUrl(widget.profilePictureUrl);
    if (url != null && url.trim().isNotEmpty) {
      return Image.network(
        url,
        width: 122,
        height: 122,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _defaultProfileIcon(),
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return const Icon(
      Icons.person,
      color: Color(0xFFA7A7A0),
      size: 74,
    );
  }

  String? _avatarUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (!trimmed.contains('res.cloudinary.com') ||
        !trimmed.contains('/upload/')) {
      return trimmed;
    }

    return trimmed.replaceFirst(
      '/upload/',
      '/upload/c_fill,g_face,w_400,h_400,q_auto,f_auto/',
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final bool loading;
  final VoidCallback onMarkAllRead;
  final void Function(String type)? onNotificationTap;

  const _NotificationPanel({
    required this.notifications,
    required this.loading,
    required this.onMarkAllRead,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(
              children: [
                Text(
                  l10n.notificationsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onMarkAllRead,
                  child: Text(
                    l10n.markAllReadAction,
                    style: const TextStyle(color: Color(0xFFCBFF4D), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFCBFF4D)))
                : notifications.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noNotificationsMessage,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, i) {
                          final n = notifications[i];
                          final unread = n['read'] == false;
                          final type = n['type'] ?? '';
                          return ListTile(
                            onTap: onNotificationTap != null
                                ? () => onNotificationTap!(type)
                                : null,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: unread
                                    ? const Color(0xFFCBFF4D).withValues(alpha: 0.15)
                                    : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _iconForType(type),
                                color: unread
                                    ? const Color(0xFFCBFF4D)
                                    : Colors.white38,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n['title'] ?? '',
                              style: TextStyle(
                                color: unread ? Colors.white : Colors.white60,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              n['content'] ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: unread
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF7185),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'training_session':
        return Icons.fitness_center;
      default:
        return Icons.notifications_none;
    }
  }
}
