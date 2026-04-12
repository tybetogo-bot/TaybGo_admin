import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('repairs corrupted Arabic strings', () {
      final l = AppLocalizations(const Locale('ar'));

      expect(l.overview, 'نظرة عامة');
      expect(l.adminDashboard, 'لوحة تحكم المشرف');
      expect(l.driverSuspended('سائق'), 'تم تعليق سائق');
    });

    test('repairs accented European strings', () {
      final fr = AppLocalizations(const Locale('fr'));
      final de = AppLocalizations(const Locale('de'));

      expect(fr.overview, 'Aperçu');
      expect(de.overview, 'Übersicht');
      expect(de.resolved, 'Gelöst');
    });
  });
}
