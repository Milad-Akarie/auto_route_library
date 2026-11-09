import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #720 (auto_route 2.4.0, Flutter 2.5.0; closed as a duplicate of #717):
// pushing the same route again from inside itself, with a different argument,
// did nothing visible until a hot reload.
// Setup: '/' is a shell with a tab-like page 'FavouriteRoute'; the root also
// has 'GenericRoute' with an int argument.
// Steps: on FavouriteRoute, tap 'push new route' (GenericRoute 1); on it tap
// 'push new route' through the root router (GenericRoute 2); once more.
// Should: each tap shows a new page; the root stack is
// [MainRoute, GenericRoute, GenericRoute, GenericRoute] and 'Generic no. 3'
// is on screen.
void main() {
  testWidgets('Pushing GenericRoute from itself shows each new page', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: 'favourite',
              initial: true,
              page: PageInfo(
                'FavouriteRoute',
                builder: (_) => Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => context.router.push(
                      const NamedRoute('GenericRoute', args: 1),
                    ),
                    child: const Text('push new route'),
                  ),
                ),
              ),
            ),
          ],
        ),
        AutoRoute(
          path: '/generic',
          page: PageInfo(
            'GenericRoute',
            builder: (data) {
              final count = data.args! as int;
              return Builder(
                builder: (context) => Column(
                  children: [
                    Text('Generic no. $count'),
                    ElevatedButton(
                      onPressed: () => context.router.root.push(
                        NamedRoute('GenericRoute', args: count + 1),
                      ),
                      child: const Text('push new route'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    await tester.tap(find.text('push new route'));
    await tester.pumpAndSettle();
    expect(find.text('Generic no. 1'), findsOneWidget);

    await tester.tap(find.text('push new route'));
    await tester.pumpAndSettle();
    expect(find.text('Generic no. 2'), findsOneWidget);

    await tester.tap(find.text('push new route'));
    await tester.pumpAndSettle();
    expect(find.text('Generic no. 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), [
      'MainRoute',
      'GenericRoute',
      'GenericRoute',
      'GenericRoute',
    ]);
  });
}
