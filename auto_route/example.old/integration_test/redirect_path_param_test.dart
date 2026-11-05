import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// An encoded '/' reaches a path param whole, also through a redirect.
// https://github.com/Milad-Akarie/auto_route_library/issues/2212
// Headless test: auto_route/test/redirect_path_param_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(page: _CmsRoute.page, path: '/cms/:path'),
        RedirectRoute(path: '/test1/:path', redirectTo: '/cms/:path'),
      ],
    );
  });

  // Steps: open the app at '/test1/a%2Fb', which a RedirectRoute sends to
  // '/cms/:path'.
  // Should: the page reads 'a/b', and the url, and on web the address
  // bar, is '/cms/a%2Fb'.
  testWidgets('A redirect passes an encoded "/" on whole', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/test1/a%2Fb');
    expect(find.text('Cms a/b'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/cms/a%2Fb');
    await expectBrowserUrl('/cms/a%2Fb');
  });
}

class _CmsRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'CmsRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) =>
        Text('Cms ${data.inheritedPathParams.getString('path')}'),
  );
}
