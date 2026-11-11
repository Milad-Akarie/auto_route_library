import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';
import 'universal_link_test.dart' show didSendPlatformLink;

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// https://github.com/Milad-Akarie/auto_route_library/issues/1687
// The example the README shows next to deepLinkTransformer: a custom-scheme
// link with no host, myapp://page/sub-page, reaches the router as /sub-page,
// because the platform reads 'page' as the host (the breaking change in
// commit 97ed2f24). The transformer below puts the host back in front of the
// path. The transformer is copied from the README; keep both the same.
// Steps: send myapp://page/sub-page while the app runs, without and with the
// transformer.
// Should: without it the link opens the route at /sub-page; with it, the
// route at /page/sub-page.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
      AutoRoute(page: _page('SubPageRoute'), path: '/sub-page'),
      AutoRoute(page: _page('PageSubPageRoute'), path: '/page/sub-page'),
    ],
  );

  testWidgets('A custom-scheme link with no host reaches the router without '
      'its first segment', (tester) async {
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());

    await didSendPlatformLink(tester, 'myapp://page/sub-page');

    expectCurrentPage(router, 'SubPageRoute');
  });

  testWidgets(
    'The README transformer puts the host back in front of the path',
    (tester) async {
      final router = buildRouter();
      await pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkTransformer: (uri) {
            if (uri.scheme == 'myapp' && uri.host.isNotEmpty) {
              return SynchronousFuture(
                uri.replace(host: '', path: '/${uri.host}${uri.path}'),
              );
            }
            return SynchronousFuture(uri);
          },
        ),
      );

      await didSendPlatformLink(tester, 'myapp://page/sub-page');

      expectCurrentPage(router, 'PageSubPageRoute');
    },
  );
}
