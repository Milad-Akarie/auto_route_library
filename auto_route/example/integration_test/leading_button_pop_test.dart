import 'package:example/web_demo/router/web_router.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// AutoLeadingButton goes back to the previous page.
// https://github.com/Milad-Akarie/auto_route_library/issues/1837
// Headless test: auto_route/test/leading_button_pop_test.dart
//
// Drives the example's web demo router, the app the reporter used, signed in
// from the start (its login page needs the demo's App widget).
// Steps: tap 'Navigate to user/2', then the user page's leading button.
// Then open the user page again, tap 'Posts -> ' (its guard opens the verify
// page on the root router), and tap the back button twice.
// Reported: the leading button on the user page did nothing, both times.
// Should: each tap goes back one page, ending on the home page.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;
  late WebAppRouter router;
  setUp(() {
    authService = AuthService()..isAuthenticated = true;
    router = WebAppRouter(authService);
  });

  Future<void> openUserPage(WidgetTester tester) async {
    await tester.tap(find.text('Navigate to user/2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('User Profile : 2'), findsOneWidget);
  }

  Future<void> tapBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('the leading button on the user page goes back to the home page', (tester) async {
    await pumpRouterApp(tester, router, reevaluationNotifier: authService);
    expect(find.text('HomePage'), findsOneWidget);
    await openUserPage(tester);

    await tapBack(tester);
    expect(find.text('HomePage'), findsOneWidget);
    expect(router.stack.map((p) => p.name), [MainWebRoute.name]);
  });

  testWidgets('back from the verify page, then the leading button, goes back to the home page', (tester) async {
    await pumpRouterApp(tester, router, reevaluationNotifier: authService);
    await openUserPage(tester);

    await tester.tap(find.text('Posts -> '));
    await tester.pumpAndSettle();
    expect(router.current.name, WebVerifyRoute.name);

    await tapBack(tester);
    expect(find.textContaining('User Profile : 2'), findsOneWidget);

    await tapBack(tester);
    expect(find.text('HomePage'), findsOneWidget);
    expect(router.stack.map((p) => p.name), [MainWebRoute.name]);
  });
}
