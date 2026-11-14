import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../widgets/animated_3d.dart';
import '../widgets/skeuo.dart';
import 'mfa_screen.dart';
import 'otp_screen.dart';

/// Login screen for the Movers customer app.
///
/// Layout is a single scrollable column: a rounded dark hero with an animated
/// 3D truck, followed by a white sign-in sheet. Nothing is absolutely
/// positioned over the form, so text can never overlap on any screen size.
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
    } else if (widget.auth.pendingMfa != null) {
      _openMfa(email);
    }
  }

  /// Opens the multi-factor code screen after a password sign-in that was
  /// answered with a challenge. Navigation mirrors [_openOtp]: the login
  /// screen stays underneath and pops once the code is accepted.
  void _openMfa(String email) {
    FocusScope.of(context).unfocus();
    final loginNavigator = Navigator.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MfaScreen(
          auth: widget.auth,
          email: email,
          onVerified: () {
            widget.onAuthenticated?.call();
            WidgetsBinding.instance
                .addPostFrameCallback((_) => loginNavigator.maybePop());
          },
        ),
      ),
    );
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
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return Scaffold(
          backgroundColor: MoversApp.surfaceMuted,
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoginHero(onBack: () => Navigator.of(context).maybePop()),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, bottomInset + 28),
                  child: SkeuoCard(
                    radius: 26,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Welcome back',
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in with your ${MoversApp.appName} customer account to book and track moves.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 22),
                        SkeuoField(
                          controller: _emailController,
                          accent: MoversApp.brandOrange,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          label: 'Email address',
                          hint: 'you@marketgo.com',
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                        const SizedBox(height: 16),
                        SkeuoField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          accent: MoversApp.brandOrange,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _signIn(),
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            tooltip:
                                _obscure ? 'Show password' : 'Hide password',
                          ),
                        ),
                        if (widget.auth.error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: widget.auth.error!),
                        ],
                        const SizedBox(height: 20),
                        SkeuoButton(
                          label: 'Sign in',
                          icon: Icons.login_rounded,
                          color: MoversApp.brandOrange,
                          height: 56,
                          loading: widget.auth.loading,
                          onPressed: widget.auth.loading ? null : _signIn,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or continue with',
                                  style: theme.textTheme.bodyMedium),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _OutlineAction(
                          icon: Icons.phone_iphone_rounded,
                          label: 'Phone',
                          onTap: _openOtp,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'By continuing you agree to the ${MoversApp.appName} Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

/// Dark, rounded hero with an animated isometric truck. All content lives in a
/// padded column so headings, subtitle and the illustration never collide.
class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final deep =
        Color.lerp(MoversApp.brandOrangeDark, const Color(0xFF0E1116), 0.74)!;
    final deeper =
        Color.lerp(MoversApp.brandOrangeDark, const Color(0xFF0E1116), 0.90)!;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deep, deeper],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: PulsingGlow(
                diameter: 250,
                color: MoversApp.brandOrange.withOpacity(0.55),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: GlowOrb(
                diameter: 230,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, topInset + 6, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack,
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      const _SecurePill(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: SizedBox(
                      width: 230,
                      child: MovingTruck3D(size: 230),
                    ),
                  ),
                  const Text(
                    'Move anything,\nanywhere.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pickup trucks, vans and lorries — booked in seconds with '
                    'live tracking and upfront prices.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      height: 1.5,
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
}

class _SecurePill extends StatelessWidget {
  const _SecurePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded,
              size: 15, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            'Secure',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.12),
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon),
    );
  }
}

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF6C9C6)),
        boxShadow: Skeuo.insetShadows(tint: const Color(0xFF8F1D16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3261E), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8F1D16),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
    return SkeuoButton(
      label: label,
      icon: icon,
      onPressed: onTap,
      height: 52,
      radius: 14,
      color: Colors.white,
      textColor: MoversApp.ink,
      iconColor: MoversApp.brandOrangeDark,
    );
  }
}
