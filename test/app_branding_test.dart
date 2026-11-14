import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movers/app.dart';
import 'package:movers/services/settings_service.dart';

void main() {
  test('App metadata and theme overrides can return to inherited defaults', () {
    final custom = AppSettings.fromJson({
      'app_name': 'Acme App',
      'brand_color': '#123456',
      'brand_dark_color': '#112233',
      'brand_light_color': '#DDEEFF',
      'font_family': 'Poppins',
      'logo_url': 'https://example.test/logo.png',
      'release_version': '2.1.0',
      'release_date': '2026-11-13',
      'powered_by': 'Acme'
    });
    MoversApp.applyBranding(custom);
    expect(MoversApp.brandOrange, const Color(0xFF123456));
    expect(MoversApp.activeFontFamily, 'Poppins');
    expect(custom.releaseVersion, '2.1.0');
    expect(custom.releaseDate, '2026-11-13');
    expect(custom.poweredBy, 'Acme');
    const defaults = AppSettings();
    MoversApp.applyBranding(defaults);
    expect(MoversApp.brandOrange, defaults.brandColor);
    expect(MoversApp.fontFamily, '');
  });
}
