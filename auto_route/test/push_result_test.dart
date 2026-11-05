import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/635
  // Steps: a parent page does `router.push(ChildRoute()).then(...)`, the child
  // page calls `router.pop()` with no argument.
  // Reported: the `then` block never ran after `pop()`, only after `pop(null)`.
  // Should: it runs for both, with null, as with Navigator.push.
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(page: _ChildRoute.page, path: '/child'),
      ],
    );
  });

  testWidgets('the future of push completes with null after pop()', (tester) async {
    await pumpRouterApp(tester, router);
    final results = <Object?>[];
    unawaited(router.push<String>(const _ChildRoute()).then(results.add));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('the future of push completes with null after pop(null)', (tester) async {
    await pumpRouterApp(tester, router);
    final results = <Object?>[];
    unawaited(router.push<String>(const _ChildRoute()).then(results.add));
    await tester.pumpAndSettle();

    // The explicit null is what the test is about, so it is passed as a value.
    String? nothing;
    router.pop(nothing);
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('the future of push completes with the result of pop(value)', (tester) async {
    await pumpRouterApp(tester, router);
    final results = <Object?>[];
    unawaited(router.push<String>(const _ChildRoute()).then(results.add));
    await tester.pumpAndSettle();

    router.pop('done');
    await tester.pumpAndSettle();

    expect(results, ['done']);
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Home')));
}

class _ChildRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'ChildRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Child')));
}
