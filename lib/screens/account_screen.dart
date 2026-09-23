import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/mover_service.dart';
import '../widgets/common.dart';
import 'delivery_addresses_screen.dart';
import 'faq_screen.dart';
import 'favourites_screen.dart';
import 'login_screen.dart';
import 'my_moves_screen.dart';
import 'payment_methods_screen.dart';

/// Account tab — shows the signed-in profile or the sign-in prompt.
class AccountTab extends StatelessWidget {
  const AccountTab({
    super.key,
    required this.auth,
    required this.movers,
    this.onLogout,
  });

  final AuthModel auth;
  final MoverService movers;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    if (!auth.isAuthenticated) {
      return AppScrollTab(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader('Account')),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: MoversApp.brandOrangeLight,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(Icons.person_outline_rounded,
                          size: 36, color: MoversApp.brandOrangeDark),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sign in to manage your account',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('View bookings, update details and more.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LoginScreen(auth: auth),
                        ),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final user = auth.user!;
    final menu = [
      (
        Icons.receipt_long_rounded,
        'My moves',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: MyMovesTab(auth: auth, movers: movers),
            ),
          ),
        ),
        const Color(0xFF2563EB),
      ),
      (
        Icons.location_on_rounded,
        'Delivery addresses',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DeliveryAddressesScreen(),
          ),
        ),
        const Color(0xFFEA580C),
      ),
      (
        Icons.credit_card_rounded,
        'Payment methods',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PaymentMethodsScreen(),
          ),
        ),
        const Color(0xFF7C3AED),
      ),
      (
        Icons.favorite_border_rounded,
        'Favourites',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FavouritesScreen(),
          ),
        ),
        const Color(0xFFDB2777),
      ),
      (
        Icons.help_outline_rounded,
        'Help & FAQ',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
        ),
        const Color(0xFF16A34A),
      ),
    ];

    return AppScrollTab(
      slivers: [
        const SliverToBoxAdapter(child: PageHeader('Account')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF171B21), Color(0xFF262B33)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 26, offset: Offset(0, 12)),
                  BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -40,
                    child: _ProfileGlow(
                      diameter: 200,
                      color: MoversApp.brandOrange.withOpacity(0.30),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: MoversApp.brandOrangeLight,
                          child: Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: MoversApp.brandOrangeDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: TextStyle(
                              fontSize: 13, color: Colors.white.withOpacity(0.55))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(menu.length, (index) {
                final (icon, label, onTap, color) = menu[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index < menu.length - 1 ? 10 : 0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEAF0EE)),
                          boxShadow: tileShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF9AA1AA)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () => auth.signOut().then((_) => onLogout?.call()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileGlow extends StatelessWidget {
  const _ProfileGlow({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}