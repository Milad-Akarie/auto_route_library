import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../no_op.dart';
import '../router_test_utils.dart';

// flutter/flutter#154729: a button in a modal bottom sheet, open over the
// only page, opens page B in place of what is on screen.
// The reporter's steps: on Home, open a bottom sheet; tap its button, then
// pop B. With Navigator.pushReplacement the sheet's route is replaced, so B
// shows over Home and pop returns to Home.
// In auto_route, replace works on pages, as documented: it replaces Home,
// the page under the sheet, which closes with it. popAndPush is the
// pushReplacement of the report: it pops the sheet and pushes B.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, initial: true),
        AutoRoute(page: _page('B')),
      ],
    );
  });

  List<String> names() =>
      router.stack.map((page) => page.routeData.name).toList();

  Future<void> openSheet(
    WidgetTester tester,
    void Function(StackRouter router) fromSheet,
  ) async {
    _fromSheet = fromSheet;
    await pumpRouterApp(tester, router);
    await tester.tap(find.text('Show bottom sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Push to page B'), findsOneWidget);
  }

  testWidgets(
    'replace from the sheet replaces the page under it, and the sheet closes',
    (tester) async {
      await openSheet(
        tester,
        (activeRouter) => activeRouter.replace(const PageRouteInfo('B')),
      );

      await tester.tap(find.text('Push to page B'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      expect(names(), ['B']);
      expectTopPage(router, 'B');
      expect(router.canPop(), isFalse);
      expect(await router.maybePop(), isFalse);
      await tester.pumpAndSettle();
      expectTopPage(router, 'B');
    },
  );

  testWidgets(
    'popAndPush from the sheet closes it and shows B over Home, and pop '
    'returns to Home',
    (tester) async {
      await openSheet(
        tester,
        (activeRouter) => activeRouter.popAndPush(const PageRouteInfo('B')),
      );

      await tester.tap(find.text('Push to page B'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      expect(names(), [_HomeRoute.name, 'B']);
      expectTopPage(router, 'B');

      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after router.pop()');
      expect(names(), [_HomeRoute.name]);
      expectTopPage(router, _HomeRoute.name);
    },
  );
}

void Function(StackRouter router) _fromSheet = ignoreArgument;

abstract final class _HomeRoute {
  static const String name = 'Home';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            const Text(name),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => TextButton(
                  onPressed: () => _fromSheet(sheetContext.router),
                  child: const Text('Push to page B'),
                ),
              ),
              child: const Text('Show bottom sheet'),
            ),
          ],
        ),
      ),
    ),
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
