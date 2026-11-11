import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/picker_router.dart';

// A page class with type parameters gets a generic route, which builds the
// page with the type it is pushed with.
// https://github.com/Milad-Akarie/auto_route_library/issues/2050 (also #1879 and
// #1739)
// Headless tests: auto_route/test/generic_page/generic_page_test.dart
// The router and its page are in support/picker_router.dart, with the router
// generated next to it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('generic page', () {
    // Steps: push PickerRoute<int> with the items 1, 2 and 3, then tap item 2.
    // Should: the page is a PickerView<int>, and the push completes with the
    // int 2.
    testWidgets(
      'Pushing PickerRoute<int> opens PickerView<int>, which pops with an int',
      (tester) async {
        final router = PickerRouter();
        await pumpRouterApp(tester, router);
        final result = router.push<int>(
          PickerRoute<int>(items: const [1, 2, 3]),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PickerView<int>), findsOneWidget);
        await expectBrowserUrl('/picker?title=Pick');
        await tester.tap(find.text('Item 2'));
        await tester.pumpAndSettle();
        final picked = await result;
        expect(picked, 2);
        expect(picked, isA<int>());
      },
    );

    // Steps: open the app at the deep link /picker?title=Colors.
    // Should: the page opens with no items and the title from the url.
    testWidgets('A deep link opens the generic page', (tester) async {
      final router = PickerRouter();
      await pumpRouterApp(tester, router, initialLink: '/picker?title=Colors');
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate((widget) => widget is PickerView),
        findsOneWidget,
      );
      expect(find.text('Colors from 0'), findsOneWidget);
    });
  });
}
