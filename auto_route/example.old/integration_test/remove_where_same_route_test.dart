import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// removeWhere removes the page it matches, not the top page of the same route.
// https://github.com/Milad-Akarie/auto_route_library/issues/1943
// Headless test: auto_route/test/simple_router/remove_where_same_route_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(page: _FormRoute.page, path: '/form'),
        AutoRoute(page: _InfoRoute.page, path: '/info'),
      ],
    );
  });

  // Steps: push a form, replace it with a loading InfoRoute that has a key,
  // push a success InfoRoute over it, then removeWhere the InfoRoute holding
  // the loader's key.
  // Should: only the loading page goes; the success page stays on screen.
  testWidgets(
    'removeWhere removes the matching page, not the top page of the same route',
    (tester) async {
      const loaderKey = ValueKey('loader');
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _FormRoute()));
      await tester.pumpAndSettle();
      unawaited(
        router.replace(_InfoRoute(key: loaderKey, title: 'Processing')),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(_InfoRoute(title: 'Success')));
      await tester.pumpAndSettle();

      router.removeWhere(
        (route) =>
            route.args is _InfoRouteArgs &&
            (route.args! as _InfoRouteArgs).key == loaderKey,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), [
        _HomeRoute.name,
        _InfoRoute.name,
      ]);
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Processing'), findsNothing);
    },
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text('Home'))),
  );
}

class _FormRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'FormRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text('Form'))),
  );
}

class _InfoRouteArgs {
  const new({required this.title, this.key});

  final Key? key;
  final String title;
}

class _InfoRoute extends PageRouteInfo<_InfoRouteArgs> {
  new({required String title, Key? key})
    : super(
        name,
        args: _InfoRouteArgs(key: key, title: title),
      );

  static const String name = 'InfoRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_InfoRouteArgs>();
      return Scaffold(
        key: args.key,
        body: SafeArea(child: Text(args.title)),
      );
    },
  );
}
