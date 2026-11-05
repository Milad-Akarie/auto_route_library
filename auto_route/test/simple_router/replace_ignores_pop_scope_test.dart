import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/99706
  // A page with PopScope(canPop: false) asks the user before it closes. The
  // reporter's go() went past it. In auto_route, pop() and system back ask the
  // PopScope; navigate() and replaceAll() remove the page without asking, as
  // the README says. Steps: open the guarded page, pop (asked, stays), then
  // replaceAll (not asked, replaced).
  testWidgets('pop() asks a PopScope, replaceAll() does not (flutter/flutter#99706)', (tester) async {
    var asked = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => const CenteredNamedPage('HomeRoute')),
        NamedRouteDef(
          name: 'EditRoute',
          path: '/edit',
          builder: (_, _) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) => asked++,
            child: const CenteredNamedPage('EditRoute'),
          ),
        ),
        NamedRouteDef(name: 'OtherRoute', path: '/other', builder: (_, _) => const CenteredNamedPage('OtherRoute')),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/edit'));
    await tester.pumpAndSettle();

    await router.maybePop();
    await tester.pumpAndSettle();
    expect(asked, 1);
    expectCurrentPage(router, 'EditRoute');

    unawaited(router.replaceAll([const NamedRoute('OtherRoute')]));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expectCurrentPage(router, 'OtherRoute');
  });
}
