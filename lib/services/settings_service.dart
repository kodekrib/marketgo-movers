import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';

class AppSettings {
  final String releaseVersion;
  final String releaseDate;
  final String poweredBy;
  final String description;
  final String appName;
  final String logoUrl;
  final Color brandColor;
  final Color brandDarkColor;
  final Color brandLightColor;
  final String fontFamily;
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
  final bool maintenanceMode;
  final String supportEmail;
  final String supportPhone;

  const AppSettings({
    this.releaseVersion = '',
    this.releaseDate = '',
    this.poweredBy = 'MarketGO',
    this.description = '',
    this.appName = 'MarketGO Movers',
    this.logoUrl = '',
    this.brandColor = const Color(0xFFE302A7),
    this.brandDarkColor = const Color(0xFFC4039A),
    this.brandLightColor = const Color(0xFFF8E2F2),
    this.fontFamily = '',
    this.currencyCode = 'NGN',
    this.currencySymbol = '₦',
    this.currencyName = 'Nigerian Naira',
    this.maintenanceMode = false,
    this.supportEmail = '',
    this.supportPhone = '',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      releaseVersion: json['release_version'] as String? ?? '',
      releaseDate: json['release_date'] as String? ?? '',
      poweredBy: json['powered_by'] as String? ?? 'MarketGO',
      description: json['description'] as String? ?? '',
      appName: (json['app_name'] as String?) ?? 'MarketGO Movers',
      logoUrl: (json['logo_url'] as String?) ?? '',
      brandColor:
          _parseHex(json['brand_color'] as String?, const Color(0xFFE302A7)),
      brandDarkColor: _parseHex(
          json['brand_dark_color'] as String?, const Color(0xFFC4039A)),
      brandLightColor: _parseHex(
          json['brand_light_color'] as String?, const Color(0xFFF8E2F2)),
      fontFamily: (json['font_family'] as String?) ?? '',
      currencyCode: (json['currency_code'] as String?) ?? 'NGN',
      currencySymbol: (json['currency_symbol'] as String?) ?? '₦',
      currencyName: (json['currency_name'] as String?) ?? 'Nigerian Naira',
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      supportEmail: (json['support_email'] as String?) ?? '',
      supportPhone: (json['support_phone'] as String?) ?? '',
    );
  }

  static Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}

class SettingsService {
  static final current = ValueNotifier<AppSettings>(const AppSettings());
  static bool hasLoaded = false;
  static bool lastFetchFailed = false;
  static Future<AppSettings>? _pending;

  static Future<AppSettings> fetchSettings() =>
      _pending ??= _fetch().whenComplete(() => _pending = null);

  /// Fetch public app settings (no auth required).
  static Future<AppSettings> _fetch() async {
    final url = Uri.parse('${defaultApiBaseUrl()}/api/v1/settings?app=movers');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final settings =
            AppSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        hasLoaded = true;
        lastFetchFailed = false;
        current.value = settings;
        return settings;
      }
    } catch (_) {
      // Fall back to defaults when offline or the server is unreachable.
    }
    lastFetchFailed = true;
    return current.value;
  }
}
