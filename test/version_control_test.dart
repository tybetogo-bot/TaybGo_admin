import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';
import 'package:taybgoadmin/features/profile/version_control_screen.dart';

void main() {
  testWidgets('renders the version history and release dates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VersionControlScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Version control'), findsOneWidget);
    expect(find.textContaining('1.0.9+10'), findsNWidgets(2));
    expect(find.textContaining('1.0.8+9'), findsOneWidget);
    expect(find.textContaining('1.0.7+8'), findsOneWidget);
    expect(find.textContaining('1.0.6+7'), findsOneWidget);
    expect(find.textContaining('1.0.5+6'), findsOneWidget);
    expect(find.textContaining('1.0.3+4'), findsOneWidget);
    expect(find.textContaining('1.0.2+3'), findsOneWidget);
    expect(find.textContaining('Released August 22, 2026'), findsNWidgets(2));
    expect(find.textContaining('Released August 20, 2026'), findsOneWidget);
    expect(find.textContaining('Released August 11, 2026'), findsOneWidget);
    expect(find.textContaining('Released August 10, 2026'), findsOneWidget);
    expect(find.textContaining('Released August 9, 2026'), findsOneWidget);
    expect(find.text('Release history'), findsOneWidget);
  });
}
