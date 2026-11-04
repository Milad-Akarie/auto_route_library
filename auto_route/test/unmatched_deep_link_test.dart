import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [AutoRoute(page: FirstRoute.page, path: '/', initial: true)],
    );
    addTearDown(router.dispose);
  });

  Future<UrlState> parse(String link) {
    return router.defaultRouteParser().parseRouteInformation(RouteInformation(uri: Uri.parse(link)));
  }

  Matcher unresolvedError(String link) => throwsA(
    isA<FlutterError>().having(
      (e) => e.message,
      'message',
      allOf(startsWith('Can not resolve initial route'), contains('"$link"'), contains("RedirectRoute(path: '*'")),
    ),
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2119
  // Open the app with a link no route matches, as another app can send on
  // Android, such as '/maps/place?q=Lisbon'. The error should name the link and
  // the fix, not only say "Can not resolve initial route".
  testWidgets('An unmatched initial link names the link in its error', (tester) async {
    final configuration = await parse('/maps/place?q=Lisbon');
    expect(router.delegate().setInitialRoutePath(configuration), unresolvedError('/maps/place?q=Lisbon'));
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2119#issuecomment-2578628437
  // The same when a deepLinkBuilder passes the platform's link on, as the
  // comments suggest for logging it.
  testWidgets('An unmatched initial link passed on by a deepLinkBuilder names the link', (tester) async {
    final configuration = await parse('/maps/place?q=Lisbon');
    final delegate = router.delegate(deepLinkBuilder: (link) => link);
    expect(delegate.setInitialRoutePath(configuration), unresolvedError('/maps/place?q=Lisbon'));
  });
}
