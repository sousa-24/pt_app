import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'l10n/gen/app_localizations.dart';

class InviteCodeScreen extends StatefulWidget {
  final String token;

  const InviteCodeScreen({super.key, required this.token});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  String? generatedCode;
  String? expiresAt;
  bool isLoading = false;

  Future<void> generateCode() async {
    setState(() => isLoading = true);

    final data = await ApiService.post(
      context,
      '/api/v1/invite-codes/',
      widget.token,
      {},
    );

    setState(() {
      isLoading = false;
      if (data != null) {
        generatedCode = data['code'];
        expiresAt = data['expires_at'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.generateInviteCodeMenu),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.generateCodeToInviteClientMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (generatedCode != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      generatedCode!,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.expiresAtLabel(expiresAt ?? ''),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: generatedCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.codeCopiedMessage)),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.copyCodeAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : generateCode,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        generatedCode == null
                            ? l10n.generateCodeAction
                            : l10n.generateNewCodeAction,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}