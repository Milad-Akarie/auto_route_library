import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#124637: canPop read by a router listener was one frame
// late.
// Steps: a listener on the root router records canPop(); push B, then pop it.
// The listener should hear true once B is added, and false right after pop()
// returns, before any frame.
void main() {
  testWidgets('a router listener reads canPop up to date after push and pop', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('A'), initial: true),
        AutoRoute(page: _page('B')),
      ],
    );
    await pumpRouterApp(tester, router);
    final heard = <bool>[];
    void listener() => heard.add(router.canPop());
    router.addListener(listener);
    addTearDown(() => router.removeListener(listener));

    unawaited(router.push(const PageRouteInfo('B')));
    await Future<void>.value();
    expect(router.canPop(), isTrue);
    expect(heard.lastOrNull, isTrue);
    await tester.pumpAndSettle();

    router.pop();
    expect(router.canPop(), isFalse);
    expect(heard.lastOrNull, isFalse);
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse, reason: 'after router.pop()');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
