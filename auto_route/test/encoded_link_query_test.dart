import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'build_counts.dart';
import 'universal_link_test.dart' show sendPlatformLink;

// Links from the platform whose query params hold encoded characters: each
// param should read back decoded once, whether the link opens the app or
// reaches it while it runs.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
      ),
      AutoRoute(
        path: '/login',
        page: PageInfo(
          'LoginRoute',
          builder: (data) => Text(data.queryParams.rawMap.entries.map((e) => '${e.key}=${e.value}').join(', ')),
        ),
      ),
    ],
  );

  Future<void> expectLinkReads(WidgetTester tester, String link, String params) async {
    final opened = buildRouter();
    await pumpAtDeepLink(tester, opened, link, includePrefixMatches: false);
    expect(find.text(params), findsOneWidget, reason: 'opened at $link');
    await tester.pumpWidget(const SizedBox());

    final running = buildRouter();
    await pumpAtDeepLink(tester, running, '/', includePrefixMatches: false);
    await sendPlatformLink(tester, link);
    expect(find.text(params), findsOneWidget, reason: '$link sent while running');
  }

  // flutter/flutter#133567: a link with an encoded '+' and '@' in a query
  // param read back with a space for the '+'.
  // Open the app at myapp://host/login?email=test%2B2%40example.com, and send
  // the same link while it runs: the page reads test+2@example.com. The same
  // for an encoded '&', '=', '/' and '%'.
  testWidgets('A link keeps an encoded "+" in a query param', (tester) async {
    await expectLinkReads(tester, 'myapp://host/login?email=test%2B2%40example.com', 'email=test+2@example.com');
    await expectLinkReads(tester, '/login?q=a%26b%3Dc%2Fd%25e', 'q=a&b=c/d%e');
  });
}
