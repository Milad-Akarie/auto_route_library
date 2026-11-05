import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/99154
  // The books sample could not open its second tab from another page: go to
  // '/books/all' from settings showed the first tab. Steps: on '/settings',
  // navigate to the path of the second tab. The tabs page shows, with that tab
  // active and the url '/books/all'.
  testWidgets('Navigating to the path of the second tab opens it (flutter/flutter#99154)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'SettingsRoute',
          path: '/settings',
          initial: true,
          builder: (_, _) => const CenteredNamedPage('SettingsRoute'),
        ),
        NamedRouteDef(
          name: 'BooksRoute',
          path: '/books',
          builder: (_, _) => AutoTabsRouter(
            routes: const [NamedRoute('NewBooksRoute'), NamedRoute('AllBooksRoute'), NamedRoute('PopularBooksRoute')],
            builder: (context, child) => Column(
              children: [
                Text('tab ${AutoTabsRouter.of(context).activeIndex}'),
                Expanded(child: child),
              ],
            ),
          ),
          children: [
            NamedRouteDef(
              name: 'NewBooksRoute',
              path: 'new',
              builder: (_, _) => const CenteredNamedPage('NewBooksRoute'),
            ),
            NamedRouteDef(
              name: 'AllBooksRoute',
              path: 'all',
              builder: (_, _) => const CenteredNamedPage('AllBooksRoute'),
            ),
            NamedRouteDef(
              name: 'PopularBooksRoute',
              path: 'popular',
              builder: (_, _) => const CenteredNamedPage('PopularBooksRoute'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.navigatePath('/books/all'));
    await tester.pumpAndSettle();
    expect(find.text('tab 1'), findsOneWidget);
    expect(find.text('AllBooksRoute'), findsOneWidget);
    expect(router.urlState.url, '/books/all');
  });
}
