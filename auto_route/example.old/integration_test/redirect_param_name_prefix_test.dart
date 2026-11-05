import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A redirect expands a path param whose name starts another param's name whole.
// Headless tests: auto_route/test/redirect_path_param_test.dart and auto_route/test/page_route_info_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('redirect param name prefix', () {
    // Steps: open the app at '/old/1/2', which RedirectRoute(path: '/old/:pa/:path', redirectTo: '/cms/:path')
    // sends on.
    // Should: the page reads '2', and the url, and on web the address bar, is '/cms/2', not '/cms/1th'.
    testWidgets('A redirect expands a param whose name starts another whole', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, path: '/', initial: true),
          AutoRoute(page: _CmsRoute.page, path: '/cms/:path'),
          RedirectRoute(path: '/old/:pa/:path', redirectTo: '/cms/:path'),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/old/1/2');
      expect(find.text('Cms 2'), findsOneWidget);
      expect(router.urlState.uri.toString(), '/cms/2');
      await expectBrowserUrl('/cms/2');
    });
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
