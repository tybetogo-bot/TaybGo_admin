import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/auth/auth_error_keys.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('repairs corrupted Arabic strings', () {
      final l = AppLocalizations(const Locale('ar'));

      expect(l.overview, '\u0646\u0638\u0631\u0629 \u0639\u0627\u0645\u0629');
      expect(
        l.adminDashboard,
        '\u0644\u0648\u062d\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0645\u0634\u0631\u0641',
      );
      expect(
        l.driverSuspended('\u0633\u0627\u0626\u0642'),
        '\u062a\u0645 \u062a\u0639\u0644\u064a\u0642 \u0633\u0627\u0626\u0642',
      );
    });

    test('repairs accented European strings', () {
      final fr = AppLocalizations(const Locale('fr'));
      final de = AppLocalizations(const Locale('de'));

      expect(fr.overview, 'Aper\u00e7u');
      expect(de.overview, '\u00dcbersicht');
      expect(de.resolved, 'Gel\u00f6st');
    });

    test('resolves phoneAlreadyRegistered into localized copy', () {
      final en = AppLocalizations(const Locale('en'));
      final ar = AppLocalizations(const Locale('ar'));
      final nl = AppLocalizations(const Locale('nl'));
      final fr = AppLocalizations(const Locale('fr'));
      final de = AppLocalizations(const Locale('de'));

      expect(
        en.resolveError(AuthErrorKeys.phoneAlreadyRegistered),
        'This number is already registered.',
      );
      expect(
        ar.resolveError(AuthErrorKeys.phoneAlreadyRegistered),
        '\u0647\u0630\u0627 \u0627\u0644\u0631\u0642\u0645 \u0645\u0633\u062c\u0644 \u0628\u0627\u0644\u0641\u0639\u0644.',
      );
      expect(
        nl.resolveError(AuthErrorKeys.phoneAlreadyRegistered),
        'Dit nummer is al geregistreerd.',
      );
      expect(
        fr.resolveError(AuthErrorKeys.phoneAlreadyRegistered),
        'Ce num\u00e9ro est d\u00e9j\u00e0 enregistr\u00e9.',
      );
      expect(
        de.resolveError(AuthErrorKeys.phoneAlreadyRegistered),
        'Diese Nummer ist bereits registriert.',
      );
    });
  });
}
