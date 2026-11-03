import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(routes: [
      AutoRoute(
        path: '/home',
        page: _HomeRoute.page,
        initial: true,
        children: [
          AutoRoute(path: 'content/:index', page: _ContentRoute.page),
        ],
      ),
    ]);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1732
  // (and #1771, its duplicate) The home page at /home pushes its child route
  // /home/content/:index awaiting a bool, and the content page pops itself
  // with true. Entering the content page threw "type 'AutoRoutePage<dynamic>'
  // is not a subtype of type 'AutoRoutePage<bool>' in type cast".
  testWidgets('Pushing a nested route by its full path awaiting a bool shows it', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.pushPath<bool>('/home/content/1');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Content 1'), findsOneWidget);
    expect(router.urlState.url, '/home/content/1');
  });

  // The push future belongs to the route pushed. A full path is matched from
  // the root, so it pushes a new /home holding the content page; pushing the
  // content route itself, or its path relative to /home, puts it in the
  // existing home's stack, and popping it completes the push with true.
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
      push(router).then((value) {
        result = value;
        completed = true;
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Content 1'), findsOneWidget);
      expect(router.urlState.url, '/home/content/1');

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Content 1'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(completed, isTrue);
      expect(result, isTrue);
    });
  }
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Column(children: [Text('Home'), Expanded(child: AutoRouter())])),
  );
}

class _ContentRoute extends PageRouteInfo<void> {
  _ContentRoute(String index) : super(name, rawPathParams: {'index': index});

  static const String name = 'ContentRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            child: const Icon(Icons.arrow_back),
            onTap: () => context.router.pop<bool>(true),
          ),
        ),
        body: Text('Content ${data.inheritedPathParams.getString('index')}'),
      ),
    ),
  );
}
