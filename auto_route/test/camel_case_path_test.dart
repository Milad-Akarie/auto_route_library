import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _AccountRoute.page,
          path: '/account',
          children: [AutoRoute(page: _ConsentManagementRoute.page, path: 'consentManagement')],
        ),
      ],
    );
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.clearDefaultRouteNameTestValue());

  // https://github.com/Milad-Akarie/auto_route_library/issues/1763
  // Open the app from the platform's link '/account/consentManagement', to a
  // route whose path is 'consentManagement'. The camelCase path should match
  // as it is written.
  testWidgets('A deep link matches a camelCase path', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/account/consentManagement';
    await pumpRouterConfigApp(tester, router.config());
    expect(tester.takeException(), isNull);
    expect(find.text('Consent management'), findsOneWidget);
    expect(router.urlState.url, '/account/consentManagement');
  });
}

abstract final class _AccountRoute {
  static const String pageName = 'AccountRoute';
  static final PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

abstract final class _ConsentManagementRoute {
  static const String pageName = 'AccountConsentManagementScreenRoute';
  static final PageInfo page = PageInfo(pageName, builder: (_) => const Text('Consent management'));
}
