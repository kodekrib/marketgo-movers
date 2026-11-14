import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../models/faq.dart';
import '../services/api_client.dart';
import '../services/faq_service.dart';
import '../services/settings_service.dart';
import '../widgets/movers_app_bar.dart';

/// Help & FAQ — collapsible Q&A pulled from `/api/v1/faqs/movers`.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final FaqService _service = FaqService(api: ApiClient());

  List<FaqEntry> _faqs = [];
  AppSettings _settings = const AppSettings();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final settings = await SettingsService.fetchSettings();
    if (mounted) setState(() => _settings = settings);
    try {
      final faqs = await _service.byTarget('movers');
      if (!mounted) return;
      setState(() => _faqs = faqs);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tappable support actions derived from the admin-configured contacts.
  List<Widget> _contactCards() {
    final children = <Widget>[];
    final phone = _settings.supportPhone.trim();
    final email = _settings.supportEmail.trim();
    if (phone.isNotEmpty) {
      children.add(Expanded(
        child: _ContactCard(
          icon: Icons.phone_outlined,
          label: 'Call support',
          onTap: () => _launch(Uri(scheme: 'tel', path: phone)),
        ),
      ));
    }
    if (email.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 10));
      children.add(Expanded(
        child: _ContactCard(
          icon: Icons.email_outlined,
          label: 'Email us',
          onTap: () => _launch(Uri(scheme: 'mailto', path: email)),
        ),
      ));
    }
    return children;
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${uri.scheme} on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const MoversAppBar(title: 'Help & FAQ'),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF7C2D12), MoversApp.brandOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Help & FAQ',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                          'Common answers about booking, vehicles, payment and tracking.',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 40, color: Color(0xFF9AA1AA)),
                        const SizedBox(height: 12),
                        const Text('Could not load help content.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _faqs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No help content available yet.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: _faqs.length,
                        itemBuilder: (context, index) {
                          final faq = _faqs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFEAF0EE)),
                            ),
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              tilePadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              leading: CircleAvatar(
                                backgroundColor: MoversApp.brandOrangeLight,
                                radius: 16,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: MoversApp.brandOrangeDark,
                                  ),
                                ),
                              ),
                              title: Text(
                                faq.question,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    faq.answer,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            if (_contactCards().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEAF0EE))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Still need help?',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(children: _contactCards()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MoversApp.brandOrangeLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: MoversApp.brandOrangeDark),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
