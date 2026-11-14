import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'widgets/branding_host.dart';

/// MarketGO Movers — theme and app root.
/// Visual identity: warm orange accent for the heavy-moving vertical.
class MoversApp extends StatelessWidget {
  const MoversApp({super.key});

  // Fallbacks mirror the brand palette configured in the marketgo-admin panel.
  // Values are refreshed at runtime from the public /api/v1/settings endpoint.
  static Color brandOrange = const Color(0xFFE302A7);
  static Color brandOrangeDark = const Color(0xFFC4039A);
  static Color brandOrangeLight = const Color(0xFFF8E2F2);
  static const Color ink = Color(0xFF111418);
  static const Color inkSoft = Color(0xFF3A3F47);
  static const Color inkMuted = Color(0xFF5B616A);
  static const Color line = Color(0xFFE9ECF0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF6F7F9);
  static String appName = 'MarketGO Movers';
  static String fontFamily = 'Inter';
  static bool maintenanceMode = false;
  static String currencySymbol = '₦';

  /// Font families offered in the marketgo-admin panel that map to Google Fonts.
  static const List<String> _googleFonts = [
    'Poppins',
    'Inter',
    'Nunito Sans',
    'Lato',
    'Open Sans',
    'Roboto',
  ];

  /// Supported Google fonts use the admin selection. Empty/system selections
  /// use the platform font without downloading a replacement.
  static String get activeFontFamily =>
      _googleFonts.contains(fontFamily) ? fontFamily : '';

  /// [base] text theme with the active Google Font applied. The font is
  /// downloaded and cached by the google_fonts package on first use.
  static TextTheme applyFont(TextTheme base) {
    if (activeFontFamily.isEmpty) return base;
    switch (activeFontFamily) {
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme(base);
      case 'Nunito Sans':
        return GoogleFonts.nunitoSansTextTheme(base);
      case 'Lato':
        return GoogleFonts.latoTextTheme(base);
      case 'Open Sans':
        return GoogleFonts.openSansTextTheme(base);
      case 'Roboto':
        return GoogleFonts.robotoTextTheme(base);
      default:
        return GoogleFonts.interTextTheme(base);
    }
  }

  /// Apply branding loaded from the admin-managed public settings.
  static void applyBranding(AppSettings s) {
    brandOrange = s.brandColor;
    brandOrangeDark = s.brandDarkColor;
    brandOrangeLight = s.brandLightColor;
    appName = s.appName;
    fontFamily = s.fontFamily;
    if (s.currencySymbol.isNotEmpty) currencySymbol = s.currencySymbol;
    maintenanceMode = s.maintenanceMode;
  }

  @override
  Widget build(BuildContext context) =>
      BrandingHost(apply: applyBranding, builder: _buildApp);

  Widget _buildApp(BuildContext context) {
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
      extensions: [BrandingIdentity(appName)],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceMuted,
      fontFamily: activeFontFamily,
      textTheme: applyFont(const TextTheme(
        displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: -0.6,
            height: 1.06),
        headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.5,
            height: 1.15),
        headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.3),
        titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ink,
            letterSpacing: -0.2),
        titleMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 16, color: inkSoft, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, color: inkMuted, height: 1.4),
        labelLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      )),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.2),
        iconTheme: IconThemeData(color: ink),
      ),
      dividerTheme: const DividerThemeData(
          color: Color(0xFFEEF0F3), thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(
            color: Color(0xFF5B616A), fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(
            color: Color(0xFF9AA1AA), fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: Color(0xFFE2E5EA)),
          minimumSize: const Size(0, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) =>
          MaintenanceGate(child: child ?? const SizedBox.shrink()),
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
