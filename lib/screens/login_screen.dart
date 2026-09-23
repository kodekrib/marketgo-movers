import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

/// Login screen for the Movers customer app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, this.onAuthenticated});

  final AuthModel auth;
  final VoidCallback? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      widget.auth.error = 'Enter your email and password to continue.';
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      widget.auth.error = 'Enter a valid email address.';
      return;
    }

    final ok = await widget.auth.signIn(email, password);
    if (!mounted) return;
    if (ok) {
      widget.onAuthenticated?.call();
      Navigator.of(context).maybePop();
    }
  }

  void _useDemo(String email) {
    _emailController.text = email;
    _passwordController.text = 'Customer@123';
  }

  void _signInTest() {
    FocusScope.of(context).unfocus();
    widget.auth.enterDemoMode();
    widget.onAuthenticated?.call();
    Navigator.of(context).maybePop();
  }

  /// Opens the phone/OTP sign-in flow. The OTP screen verifies the code with
  /// the backend and enters the authenticated session before navigating on.
  void _openOtp() {
    FocusScope.of(context).unfocus();
    final loginNavigator = Navigator.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          auth: widget.auth,
          onVerified: () {
            widget.onAuthenticated?.call();
            WidgetsBinding.instance
                .addPostFrameCallback((_) => loginNavigator.maybePop());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: MoversApp.surfaceMuted,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C2D12), MoversApp.brandOrange],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.sailing_rounded,
                        color: Colors.white, size: 56),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.12),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Back',
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                      Text(
                        MoversApp.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Sign in to book heavy-moving services with pickup trucks, vans and lorries.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                        decoration: const BoxDecoration(
                          color: MoversApp.surfaceMuted,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Sign in', style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Use your MarketGO customer account.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: MoversApp.brandOrangeLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: MoversApp.brandOrange.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.flash_on_rounded,
                                      color: MoversApp.brandOrangeDark),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'No server? Explore the full app now',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: MoversApp.brandOrangeDark,
                                          ),
                                        ),
                                        Text(
                                          'Skips sign-in entirely for testing.',
                                          style: TextStyle(
                                            color: MoversApp.brandOrangeDark,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _signInTest,
                                    style: TextButton.styleFrom(
                                      foregroundColor: MoversApp.brandOrangeDark,
                                    ),
                                    child: const Text('Test mode'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text('Demo account', style: theme.textTheme.bodySmall),
                                const Spacer(),
                                ActionChip(
                                  avatar: Icon(Icons.bolt,
                                      size: 16, color: MoversApp.brandOrange),
                                  label: const Text('Customer'),
                                  backgroundColor: MoversApp.brandOrangeLight,
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: MoversApp.brandOrangeDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onPressed: () => _useDemo('customer@marketgo.com'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                hintText: 'you@marketgo.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _signIn(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  tooltip: _obscure ? 'Show password' : 'Hide password',
                                ),
                              ),
                            ),
                            if (widget.auth.error != null) ...[
                              const SizedBox(height: 12),
                              Container(
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
                                        widget.auth.error!,
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
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: widget.auth.loading ? null : _signIn,
                                child: widget.auth.loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text('or continue with',
                                      style: theme.textTheme.bodyMedium),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _OutlineAction(
                                    icon: Icons.phone_iphone_rounded,
                                    label: 'Phone',
                                    onTap: _openOtp,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _OutlineAction(
                                    icon: Icons.mark_email_read_outlined,
                                    label: 'OTP',
                                    onTap: _openOtp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: Color(0xFFD5DAE1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: MoversApp.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: MoversApp.brandOrangeDark),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}