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
        AutoRoute(path: '/other', page: _OtherRoute.page),
        AutoRoute(
          path: '/home',
          page: _HomeRoute.page,
          initial: true,
          children: [AutoRoute(path: 'content/:index', page: _ContentRoute.page)],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1732
  // (and #1771, its duplicate) The home page at /home pushes its child route
  // /home/content/:index awaiting a bool, and the content page pops itself
  // with true. Entering the content page threw "type 'AutoRoutePage<dynamic>'
  // is not a subtype of type 'AutoRoutePage<bool>' in type cast".
  testWidgets('Pushing a nested route by its full path awaiting a bool shows it', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.pushPath<bool>('/home/content/1'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Content 1'), findsOneWidget);
    expect(router.urlState.url, '/home/content/1');
  });

  // The push future belongs to the route pushed. Pushing the content route
  // itself, or its path relative to /home, puts it in the existing home's
  // stack, and popping it completes the push with true.
  for (final (how, push) in [
    ('push()', (StackRouter root) => root.push<bool>(_ContentRoute('1'))),
    (
      "pushPath('content/1') on the home's router",
      (StackRouter root) => root.innerRouterOf<StackRouter>(_HomeRoute.name)!.pushPath<bool>('content/1'),
    ),
  ]) {
    testWidgets('A nested route pushed with $how returns its bool result', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      bool? result;
      var completed = false;
      unawaited(
        push(router).then((value) {
          result = value;
          completed = true;
        }),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Content 1'), findsOneWidget);
      expect(router.urlState.url, '/home/content/1');

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after tester.tap(find.byIcon(Icons.arrow_back))');
      expect(find.text('Content 1'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(completed, isTrue);
      expect(result, isTrue);
    });
  }

  testWidgets("pushPath('/home/content/1') with the home on top returns the content's bool", (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    bool? result;
    unawaited(router.pushPath<bool>('/home/content/1').then((value) => result = value));
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['HomeRoute']);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(result, isTrue);
  });

  // When the parent is the page on top, its router takes the content page, so
  // the push future belongs to the content page as in the tests above. When
  // another page is on top, no open parent can take it and the full path
  // pushes a new /home holding the content page, the same as pushing the
  // parent with its children: the future then belongs to that new /home,
  // which is what that push names, and popping the content page leaves it
  // pending. That is intended; the content page alone is pushed with
  // push(_ContentRoute) or the path relative to the home's router.
  for (final (how, push) in [
    ("pushPath('/home/content/1')", (StackRouter root) => root.pushPath<bool>('/home/content/1')),
    (
      'push(HomeRoute(children: [ContentRoute]))',
      (StackRouter root) => root.push<bool>(_HomeRoute(children: [_ContentRoute('1')])),
    ),
  ]) {
    testWidgets('$how with another page on top pushes a new parent whose future waits for the parent', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const _OtherRoute()));
      await tester.pumpAndSettle();
      expect(router.stack.map((page) => page.name), ['HomeRoute', 'OtherRoute']);
      var completed = false;
      unawaited(push(router).then((_) => completed = true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), ['HomeRoute', 'OtherRoute', 'HomeRoute']);
      expect(find.text('Content 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after tester.tap(find.byIcon(Icons.arrow_back))');
      expect(completed, isFalse);
    });
  }
}

class _HomeRoute extends PageRouteInfo<void> {
  const new({required List<PageRouteInfo> children}) : super(name, initialChildren: children);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(
      body: Column(
        children: [
          Text('Home'),
          Expanded(child: AutoRouter()),
        ],
      ),
    ),
  );
}

class _ContentRoute extends PageRouteInfo<void> {
  new(String index) : super(name, rawPathParams: {'index': index});

  static const String name = 'ContentRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          leading: GestureDetector(child: const Icon(Icons.arrow_back), onTap: () => context.router.pop(true)),
        ),
        body: Text('Content ${data.inheritedPathParams.getString('index')}'),
      ),
    ),
  );
}

class _OtherRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'OtherRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Other')));
}
