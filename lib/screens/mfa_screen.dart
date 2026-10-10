import 'package:flutter/material.dart';
import '../app.dart';
import '../services/auth_service.dart';

/// Multi-factor code screen shown after a password sign-in that answered with
/// `mfa_required`.
///
/// The one-time code (delivered over the challenge channels, e.g. email) is
/// exchanged for a token pair through [AuthModel.verifyMfaCode]; on success
/// the caller's `onVerified` fires and the screen pops.
class MfaScreen extends StatefulWidget {
  const MfaScreen({
    super.key,
    required this.auth,
    required this.email,
    required this.onVerified,
  });

  final AuthModel auth;
  final String email;
  final VoidCallback onVerified;

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final _codeController = TextEditingController();
  String? _localError;
  bool _verified = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits != value) _codeController.text = digits;
    if (_localError != null) setState(() => _localError = null);
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _localError = 'Enter the one-time code to continue.');
      return;
    }
    setState(() => _localError = null);
    final ok = await widget.auth.verifyMfaCode(code);
    if (!mounted) return;
    if (ok) {
      _verified = true;
      widget.onVerified();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final devCode = widget.auth.pendingMfa?.devCode;
        final error = _localError ?? widget.auth.error;
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            // Leaving the challenge invalidates it on screen; skip the
            // cleanup once the code has been accepted.
            if (didPop && !_verified) widget.auth.cancelMfa();
          },
          child: Scaffold(
            backgroundColor: MoversApp.surfaceMuted,
            appBar: AppBar(
              backgroundColor: MoversApp.surfaceMuted,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: true,
              title: const Text('Two-factor verification'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: MoversApp.brandOrangeLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.shield_outlined,
                        size: 36, color: MoversApp.brandOrangeDark),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter the security code',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We emailed a one-time code to ${widget.email}. '
                    'Enter it below to finish signing in.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (devCode != null && devCode.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MoversApp.brandOrangeLight,
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: MoversApp.brandOrangeDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Developer preview — your code is $devCode.',
                              style: TextStyle(
                                color: MoversApp.brandOrangeDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textInputAction: TextInputAction.done,
                    maxLength: 8,
                    maxLines: 1,
                    autofocus: true,
                    onChanged: _onCodeChanged,
                    onSubmitted: (_) => _verify(),
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: 'One-time code',
                      hintText: '123456',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                  if (error != null) _ErrorBanner(message: error),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: widget.auth.loading ? null : _verify,
                      child: widget.auth.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.6, color: Colors.white),
                            )
                          : const Text('Verify & sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFB3261E), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF8F1D16),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
