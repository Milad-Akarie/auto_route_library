import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A deep link matches a camelCase path.
// https://github.com/Milad-Akarie/auto_route_library/issues/1763
// Headless test: auto_route/test/camel_case_path_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tearDown(binding.platformDispatcher.clearDefaultRouteNameTestValue);

  // Steps: open the app from the platform's link '/account/consentManagement',
  // to a route whose path is 'consentManagement'.
  // Should: the consent page opens, and the url, and on web the address bar,
  // keeps the camelCase path.
  testWidgets('A deep link matches a camelCase path', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _AccountRoute.page,
          path: '/account',
          children: [
            AutoRoute(
              page: _ConsentManagementRoute.page,
              path: 'consentManagement',
            ),
          ],
        ),
      ],
    );
    binding.platformDispatcher.defaultRouteNameTestValue =
        '/account/consentManagement';
    await pumpRouterConfigApp(tester, router.config());
    expect(tester.takeException(), isNull);
    expect(find.text('Consent management'), findsOneWidget);
    expect(router.urlState.url, '/account/consentManagement');
    await expectBrowserUrl('/account/consentManagement');
  });
}

class _AccountRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'AccountRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

class _ConsentManagementRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'AccountConsentManagementScreenRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (_) => const Text('Consent management'),
  );
}
