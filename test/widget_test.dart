import 'package:flutter_test/flutter_test.dart';

import 'package:taybgoadmin/main.dart';
import 'package:taybgoadmin/core/services/api_service.dart';
import 'package:taybgoadmin/core/providers/auth_provider.dart';

void main() {
  testWidgets('App renders sign-in screen', (WidgetTester tester) async {
    final apiService = ApiService();
    final authProvider = AuthProvider(apiService: apiService);

    await tester.pumpWidget(TaybGoAdminApp(
      apiService: apiService,
      authProvider: authProvider,
    ));
    await tester.pumpAndSettle();

    expect(find.text('TaybGo Admin'), findsOneWidget);
  });
}
