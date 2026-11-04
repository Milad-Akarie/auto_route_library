import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#147465 and #165588: the page for an unknown url, the only
// page of the app, asked whether it can pop. go_router threw "Bad state: No
// element"; and Navigator.canPop said true but pop then failed.
// Steps: open '/missing', whose '*' route shows a page that reads
// router.canPop() and Navigator.canPop while it builds, and has a button
// calling maybePop.
// Should: both are false, nothing throws, and the button leaves the page.
void main() {
  testWidgets('The not-found page, alone, can not pop and its pop does nothing '
      '(flutter/flutter#147465, flutter/flutter#165588)', (tester) async {
    bool? routerCanPop;
    bool? navigatorCanPop;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
          path: '/',
        ),
        AutoRoute(
          path: '*',
          page: PageInfo(
            'NotFoundRoute',
            builder: (_) => Builder(
              builder: (context) {
                routerCanPop = context.router.canPop();
                navigatorCanPop = Navigator.canPop(context);
                return Scaffold(
                  body: TextButton(onPressed: () => context.router.maybePop(), child: const Text('NotFoundRoute')),
                );
              },
            ),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/missing');

    expect(tester.takeException(), isNull);
    expect(find.text('NotFoundRoute'), findsOneWidget);
    expect(routerCanPop, isFalse);
    expect(navigatorCanPop, isFalse);

    await tester.tap(find.text('NotFoundRoute'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
