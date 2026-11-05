import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Guard for flutter/flutter#170220 (the root route inside a nested Navigator
// does not know that it can be popped).
// Setup, as in the report: a home page, and a user page that holds a nested
// router with a profile page and a details page. Every nested page has an
// AppBar with an AutoLeadingButton.
// Steps: push the user page and look at the profile page's AppBar; tap its
// button; push the user page again, open the details page and tap the button.
// Happened (in Flutter): the stock AppBar of the profile page, the first
// route of its Navigator, showed no back button.
// Should: AutoLeadingButton shows the back button because a parent page can
// pop, takes the user back to the home page from the profile page, and from
// the details page to the profile page.
// Already works on dev: AutoLeadingButton asks the whole router tree
// (lib/src/router/widgets/auto_leading_button.dart).
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
        AutoRoute(
          page: PageInfo('UserRoute', builder: (_) => const AutoRouter()),
          path: '/user',
          children: [
            AutoRoute(page: _page('ProfileRoute'), path: '', initial: true),
            AutoRoute(page: _page('DetailsRoute'), path: 'details'),
          ],
        ),
      ],
    );
  });

  testWidgets('AutoLeadingButton on the first page of a nested router goes back to the page before the host', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    expect(find.byType(BackButton), findsNothing);

    unawaited(router.push(const _Route('UserRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'ProfileRoute');
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expectTopPage(router, 'HomeRoute');
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
  });

  testWidgets('AutoLeadingButton on a second nested page goes back to the first nested page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _Route('UserRoute')));
    await tester.pumpAndSettle();
    unawaited(router.innerRouterOf<StackRouter>('UserRoute')!.push(const _Route('DetailsRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'DetailsRoute');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expectTopPage(router, 'ProfileRoute');
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'UserRoute']);
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    body: Text(name),
  ),
);

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
