import 'dart:async';

import 'package:example/dollar_names/dollar_names.router.dart';
import 'package:example/dollar_names/dollar_names.router.gr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';

// #1163: a page and its parameters named with a `$` give a router that
// compiles, reads its url parameters by their names and prints its args.
// Generator test: auto_route_generator/test/route_names_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app at /users/7?tab$name=menu, then push the page with
  // venue$id 'v9'. Should: the page reads user$id and tab$name from the url,
  // then shows the pushed values, and its args print `venue$id: v9`.
  testWidgets(r'a page named with a $ opens from a link and from a push', (tester) async {
    final router = DollarNamesRouter();
    await pumpRouterApp(tester, router, initialLink: r'/users/7?tab$name=menu');
    await pumpUntilFound(tester, find.text('user 7, venue none, tab menu'));
    expect(find.text('user 7, venue none, tab menu'), findsOneWidget);

    unawaited(router.push(Venue$Route(user$id: '8', venue$id: 'v9', tab$name: 'info')));
    await pumpUntilFound(tester, find.text('user 8, venue v9, tab info'));
    expect(find.text('user 8, venue v9, tab info'), findsOneWidget);
    expect(router.current.argsAs<Venue$RouteArgs>().toString(), contains(r'venue$id: v9'));
    expect(router.urlState.uri.path, '/users/8');
    expect(router.current.queryParams.optString(r'tab$name'), 'info');
    expect(tester.takeException(), isNull);
  });
}
