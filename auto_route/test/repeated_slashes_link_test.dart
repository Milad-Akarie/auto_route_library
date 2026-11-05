import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'build_counts.dart';
import 'universal_link_test.dart' show didSendPlatformLink;

// flutter/flutter#150666: a link with repeated slashes, such as
// /items///1, matched no route.
// Open the app at /items///1, and send /items//1// while it runs: each opens
// the item page for '1', at the url /items/1.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
      ),
      AutoRoute(
        path: '/items/:id',
        page: PageInfo(
          'ItemRoute',
          builder: (data) =>
              Text('Item ${data.inheritedPathParams.getString('id')}'),
        ),
      ),
    ],
  );

  Future<RootStackRouter> pumpAtLink(WidgetTester tester, String link) async {
    final router = buildRouter();
    await pumpAtDeepLink(
      tester,
      router,
      link,
      shouldIncludePrefixMatches: false,
    );
    return router;
  }

  testWidgets('A link with repeated slashes opens its page', (tester) async {
    final opened = await pumpAtLink(tester, '/items///1');
    expect(find.text('Item 1'), findsOneWidget);
    expect(opened.currentUrl, '/items/1');
    await tester.pumpWidget(const SizedBox());

    final running = await pumpAtLink(tester, '/');
    await didSendPlatformLink(tester, '/items//1//');
    expect(
      find.text('Item 1'),
      findsOneWidget,
      reason: 'after didSendPlatformLink(tester, /items//1//)',
    );
    expect(running.currentUrl, '/items/1');
  });
}
