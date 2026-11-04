import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#134370: on a pushed page, Scaffold.showBottomSheet adds a
// local history entry, not a route.
// Steps: push the second page, open the sheet, press back (the AppBar back
// button, then system back), and once more.
// Should: the first back closes only the sheet; the next goes to Home, with no
// exception.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('HomeRoute'))),
        ),
        AutoRoute(
          path: '/sub',
          page: PageInfo('SubRoute', builder: (_) => const _Sub()),
        ),
      ],
    );
  });

  Future<void> openSheet(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('SubRoute')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsOneWidget);
  }

  testWidgets('The AppBar back button closes the sheet, then leaves the page', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsNothing);
    expectCurrentPage(router, 'SubRoute');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expectCurrentPage(router, 'HomeRoute');
  });

  testWidgets('System back closes the sheet, then leaves the page', (tester) async {
    await openSheet(tester);
    await systemBack(tester);
    expect(find.text('Sheet content'), findsNothing);
    expectCurrentPage(router, 'SubRoute');

    await systemBack(tester);
    expect(tester.takeException(), isNull);
    expectCurrentPage(router, 'HomeRoute');
  });
}

class _Sub extends StatelessWidget {
  const _Sub();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const BackButton()),
    body: Builder(
      builder: (inner) => Column(
        children: [
          const Text('SubRoute'),
          TextButton(
            onPressed: () =>
                Scaffold.of(inner).showBottomSheet((_) => const SizedBox(height: 100, child: Text('Sheet content'))),
            child: const Text('Sheet'),
          ),
        ],
      ),
    ),
  );
}
