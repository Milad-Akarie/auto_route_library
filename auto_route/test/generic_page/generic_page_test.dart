import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../router_test_utils.dart';
import 'picker_router.dart';

void main() {
  // #2050, #1879, #1739: a page class with type parameters, here
  // `PickerView<T>`, gets a generic route. Pushing `PickerRoute<int>` builds
  // `PickerView<int>`, and the page pops with an int. The router and its
  // page are in picker_router.dart, with the router generated next to it.
  testWidgets('Pushing PickerRoute<int> opens PickerView<int>, which pops with an int', (tester) async {
    final router = PickerRouter();
    await pumpRouterApp(tester, router);
    final result = router.push<int>(PickerRoute<int>(items: const [1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.byType(PickerView<int>), findsOneWidget);
    expect(router.current.args, isA<PickerRouteArgs<int>>());
    await tester.tap(find.text('Item 2'));
    await tester.pumpAndSettle();
    final picked = await result;
    expect(picked, 2);
    expect(picked, isA<int>());
  });

  testWidgets('Two pushes with different types build a page for each', (tester) async {
    final router = PickerRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(PickerRoute<String>(items: const ['a'])));
    unawaited(router.push(PickerRoute<double>(items: const [1.5])));
    await tester.pumpAndSettle();
    expect(find.byType(PickerView<double>), findsOneWidget);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(PickerView<String>), findsOneWidget);
  });

  // A link carries no type, so the page gets its type's bound, here none, so
  // dynamic, and reads its query param from the url.
  testWidgets('A deep link opens the page with the bound of its type', (tester) async {
    final router = PickerRouter();
    await pumpRouterApp(tester, router, initialLink: '/picker?title=Colors');
    expect(tester.takeException(), isNull);
    expect(find.byType(PickerView), findsOneWidget);
    expect(find.text('Colors from 0'), findsOneWidget);
  });
}
