import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/api_client.dart';

/// Public app identity and release information configured in marketgo-admin.
class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});
  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  PackageInfo? _package;
  bool _loading = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await SettingsService.fetchSettings();
    PackageInfo? package;
    try {
      package = await PackageInfo.fromPlatform();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _package = package;
      _loading = false;
      _failed = SettingsService.lastFetchFailed;
    });
    // SettingsService publishes the identity to the app theme as well.
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('App Info'), actions: [
          IconButton(
              tooltip: 'Refresh app information',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh))
        ]),
        body: ValueListenableBuilder<AppSettings>(
            valueListenable: SettingsService.current,
            builder: (context, s, _) {
              final theme = Theme.of(context);
              final logo = s.logoUrl.isEmpty
                  ? ''
                  : Uri.parse(defaultApiBaseUrl())
                      .resolve(s.logoUrl)
                      .toString();
              final version = _package == null
                  ? 'Unavailable'
                  : '${_package!.version} (${_package!.buildNumber})';
              return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        if (_loading) const LinearProgressIndicator(),
                        if (_failed)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                  'Could not refresh app information. Showing the last available details.',
                                  style: theme.textTheme.bodySmall)),
                        const SizedBox(height: 24),
                        Center(
                            child: Container(
                                width: 112,
                                height: 112,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(28)),
                                child: logo.isEmpty
                                    ? Icon(Icons.apps_rounded,
                                        size: 64,
                                        color: theme.colorScheme.primary)
                                    : Image.network(logo,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Icon(
                                            Icons.apps_rounded,
                                            size: 64,
                                            color:
                                                theme.colorScheme.primary)))),
                        const SizedBox(height: 20),
                        Text(s.appName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (s.description.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(s.description,
                                  textAlign: TextAlign.center)),
                        const SizedBox(height: 24),
                        Card(
                            child: Column(children: [
                          ListTile(
                              leading: const Icon(Icons.verified_outlined),
                              title: const Text('Installed version'),
                              subtitle: Text(version)),
                          if (s.releaseVersion.isNotEmpty)
                            ListTile(
                                leading:
                                    const Icon(Icons.new_releases_outlined),
                                title: const Text('Release version'),
                                subtitle: Text(s.releaseVersion)),
                          ListTile(
                              leading: const Icon(Icons.event_outlined),
                              title: const Text('Release date'),
                              subtitle: Text(s.releaseDate.isEmpty
                                  ? 'Not announced'
                                  : s.releaseDate)),
                          if (s.supportEmail.isNotEmpty)
                            ListTile(
                                leading: const Icon(Icons.mail_outline),
                                title: const Text('Support email'),
                                subtitle: SelectableText(s.supportEmail)),
                          if (s.supportPhone.isNotEmpty)
                            ListTile(
                                leading: const Icon(Icons.phone_outlined),
                                title: const Text('Support phone'),
                                subtitle: SelectableText(s.supportPhone)),
                        ])),
                        const SizedBox(height: 24),
                        Text('Powered by ${s.poweredBy}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium),
                      ]));
            }),
      );
}
