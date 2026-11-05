import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, initial: true),
        AutoRoute(page: _FormRoute.page),
        AutoRoute(page: _InfoRoute.page),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1943
  // From a form, replace it with a loading InfoRoute that has a key, push a
  // success InfoRoute over it, then removeWhere the route whose args hold the
  // loader's key. Only the loading page should go; the success page stays on
  // top, instead of the top page being removed with it.
  testWidgets('removeWhere removes the matching page, not the top page of the same route', (tester) async {
    const loaderKey = ValueKey('loader');
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _FormRoute()));
    await tester.pumpAndSettle();
    unawaited(router.replace(_InfoRoute(key: loaderKey, title: 'Processing')));
    await tester.pumpAndSettle();
    unawaited(router.push(_InfoRoute(title: 'Success')));
    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), [_HomeRoute.name, _InfoRoute.name, _InfoRoute.name]);

    // The reporter's check: whether the route is an InfoRoute holding the key.
    router.removeWhere((route) => route.args is _InfoRouteArgs && (route.args! as _InfoRouteArgs).key == loaderKey);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name, _InfoRoute.name]);
    expect(router.current.argsAs<_InfoRouteArgs>().title, 'Success');
    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Processing'), findsNothing);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1943
  // The page on top keeps its state when a page of the same route is removed
  // from below it.
  testWidgets('removeWhere below the top page keeps the top page state', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(_InfoRoute(title: 'Processing')));
    await tester.pumpAndSettle();
    unawaited(router.push(_InfoRoute(title: 'Success')));
    await tester.pumpAndSettle();
    final topState = tester.state(find.byType(_InfoPage));

    router.removeWhere(
      (route) => route.args is _InfoRouteArgs && (route.args! as _InfoRouteArgs).title == 'Processing',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name, _InfoRoute.name]);
    expect(tester.state(find.byType(_InfoPage)), same(topState));
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Home')));
}

class _FormRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'FormRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Form')));
}

class _InfoRouteArgs {
  const new({this.key, this.title = ''});

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
      return _InfoPage(key: args.key, title: args.title);
    },
  );
}

class _InfoPage extends StatefulWidget {
  const new({required this.title, super.key});

  final String title;

  @override
  State<_InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<_InfoPage> {
  @override
  Widget build(BuildContext context) => Scaffold(body: Text(widget.title));
}
