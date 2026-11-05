import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A nested route pushed awaiting a bool returns it when it pops itself.
// https://github.com/Milad-Akarie/auto_route_library/issues/1732 (and #1771)
// Headless tests: auto_route/test/nested_router/nested_result_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/home',
          page: _HomeRoute.page,
          initial: true,
          children: [
            AutoRoute(path: 'content/:index', page: _ContentRoute.page),
          ],
        ),
      ],
    );
  });

  // Steps: from /home, push its child /home/content/1 by its full path,
  // awaiting a bool.
  // Should: the content page shows, without the "AutoRoutePage<dynamic> is
  // not a subtype of AutoRoutePage<bool>" type error.
  testWidgets(
    'Pushing a nested route by its full path awaiting a bool shows it',
    (tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.pushPath<bool>('/home/content/1'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Content 1'), findsOneWidget);
      await expectBrowserUrl('/home/content/1');
    },
  );

  // Steps: push the content route into the home's stack awaiting a bool,
  // then tap its back icon, which pops it with true.
  // Should: the push completes with true and the home page shows.
  testWidgets('A nested route returns its bool result when it pops itself', (
    tester,
  ) async {
    await pumpRouterAppWithConfig(tester, router);
    bool? result;
    var completed = false;
    unawaited(
      router.push<bool>(_ContentRoute('1')).then((value) {
        result = value;
        completed = true;
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Content 1'), findsOneWidget);
    await expectBrowserUrl('/home/content/1');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Content 1'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(completed, isTrue);
    expect(result, isTrue);
    await expectBrowserUrl('/home');
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

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
