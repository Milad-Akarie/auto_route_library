import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/pages.dart';

// An unmatched initial link names the link in its error.
// https://github.com/Milad-Akarie/auto_route_library/issues/2119
// Headless test: auto_route/test/unmatched_deep_link_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: hand the app's router, which has only '/', the initial link
  // '/maps/place?q=Lisbon', as another app can on Android.
  // Should: the error names the link and how to send such links to a page.
  testWidgets('An unmatched initial link names the link in its error', (tester) async {
    final router = RootStackRouter.build(
      routes: [AutoRoute(page: FirstRoute.page, path: '/', initial: true)],
    );
    final configuration = await router.defaultRouteParser().parseRouteInformation(
      RouteInformation(uri: Uri.parse('/maps/place?q=Lisbon')),
    );
    await expectLater(
      router.delegate().setInitialRoutePath(configuration),
      throwsA(
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          allOf(contains('"/maps/place?q=Lisbon"'), contains("RedirectRoute(path: '*'")),
        ),
      ),
    );
  });
}
