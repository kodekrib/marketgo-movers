import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Rebuilds the theme without replacing the navigator, cart or auth session.
class BrandingHost extends StatefulWidget {
  const BrandingHost({super.key, required this.apply, required this.builder});
  final void Function(AppSettings) apply;
  final WidgetBuilder builder;
  @override
  State<BrandingHost> createState() => _BrandingHostState();
}

class _BrandingHostState extends State<BrandingHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SettingsService.current.addListener(_changed);
    if (SettingsService.hasLoaded) widget.apply(SettingsService.current.value);
  }

  void _changed() {
    if (mounted) {
      setState(() => widget.apply(SettingsService.current.value));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) SettingsService.fetchSettings();
  }

  @override
  void dispose() {
    SettingsService.current.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Includes app identity in theme equality so name-only edits refresh themed
/// screens while preserving their state and navigation stack.
@immutable
class BrandingIdentity extends ThemeExtension<BrandingIdentity> {
  const BrandingIdentity(this.name);
  final String name;
  @override
  BrandingIdentity copyWith({String? name}) =>
      BrandingIdentity(name ?? this.name);
  @override
  BrandingIdentity lerp(covariant BrandingIdentity? other, double t) =>
      t < .5 ? this : (other ?? this);
  @override
  bool operator ==(Object other) =>
      other is BrandingIdentity && name == other.name;
  @override
  int get hashCode => name.hashCode;
}
