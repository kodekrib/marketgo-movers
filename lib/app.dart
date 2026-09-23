import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';

/// MarketGO Movers — theme and app root.
/// Visual identity: warm orange accent for the heavy-moving vertical.
class MoversApp extends StatelessWidget {
  const MoversApp({super.key});

  static Color brandOrange = const Color(0xFFEA580C);
  static Color brandOrangeDark = const Color(0xFFC2410C);
  static Color brandOrangeLight = const Color(0xFFFFEDD5);
  static const Color ink = Color(0xFF111418);
  static const Color inkSoft = Color(0xFF3A3F47);
  static const Color inkMuted = Color(0xFF5B616A);
  static const Color line = Color(0xFFE9ECF0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF6F7F9);
  static String appName = 'MarketGO Movers';
  static String fontFamily = 'Helvetica Neue';
  static bool maintenanceMode = false;
  static String currencySymbol = '₦';

  /// Apply branding loaded from the admin-managed public settings.
  static void applyBranding(AppSettings s) {
    if (s.brandColor != const Color(0xFFEA580C)) brandOrange = s.brandColor;
    if (s.brandDarkColor != const Color(0xFFC2410C)) brandOrangeDark = s.brandDarkColor;
    if (s.brandLightColor != const Color(0xFFFFEDD5)) brandOrangeLight = s.brandLightColor;
    appName = s.appName;
    if (s.fontFamily.isNotEmpty) fontFamily = s.fontFamily;
    if (s.currencySymbol.isNotEmpty) currencySymbol = s.currencySymbol;
    maintenanceMode = s.maintenanceMode;
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light().colorScheme;
    final colorScheme = base.copyWith(
      primary: brandOrange,
      onPrimary: Colors.white,
      primaryContainer: brandOrangeLight,
      onPrimaryContainer: brandOrangeDark,
      secondary: brandOrangeDark,
      onSecondary: Colors.white,
      secondaryContainer: brandOrangeLight,
      onSecondaryContainer: brandOrangeDark,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      outlineVariant: line,
      error: const Color(0xFFB3261E),
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceMuted,
      fontFamily: fontFamily,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink, letterSpacing: -0.6, height: 1.06),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5, height: 1.15),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 16, color: inkSoft, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, color: inkMuted, height: 1.4),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.2),
        iconTheme: IconThemeData(color: ink),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEEF0F3), thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFF5B616A), fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: Color(0xFF9AA1AA), fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: brandOrange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: Color(0xFFE2E5EA)),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) => MaintenanceGate(child: child ?? const SizedBox.shrink()),
      home: const HomeScreen(),
    );
  }
}

/// Watches public settings and swaps the whole app to a maintenance screen
/// whenever the admin enables platform-wide maintenance mode.
class MaintenanceGate extends StatefulWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  Timer? _timer;
  bool maintenance = MoversApp.maintenanceMode;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final s = await SettingsService.fetchSettings();
    if (!mounted) return;
    final on = s.maintenanceMode;
    if (on != maintenance) {
      setState(() => maintenance = on);
    }
  }

  @override
  Widget build(BuildContext context) {
    return maintenance ? const MaintenanceScreen() : widget.child;
  }
}

/// Full-screen notice shown while the platform is under maintenance.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: MoversApp.brandOrangeLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(Icons.build_circle_rounded,
                      size: 46, color: MoversApp.brandOrangeDark),
                ),
                const SizedBox(height: 24),
                Text(
                  '${MoversApp.appName} is under maintenance',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  "We're performing scheduled maintenance right now. "
                  'Please check back shortly — we will be back up soon.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
