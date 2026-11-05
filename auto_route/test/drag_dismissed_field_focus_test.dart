import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/124778: under
  // MaterialApp.router, a TextField unfocused by a ListView's
  // keyboardDismissBehavior.onDrag got focus back after the page over it was
  // popped with Navigator.pop.
  // Steps, as in the report, on iOS: HomeRoute's ListView of five fields
  // closes the keyboard on drag. Tap the first field, drag the list, tap the
  // button that pushes SecondRoute, then tap SecondRoute's button, which
  // calls Navigator.of(context).pop().
  // Should: no field has focus and the keyboard stays closed.
  testWidgets(
    'A field unfocused by a drag stays unfocused after a pop',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => Builder(
                builder: (context) => Scaffold(
                  body: ListView(
                    keyboardDismissBehavior: .onDrag,
                    children: [for (var i = 0; i < 5; i++) TextField(key: Key('field $i'))],
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => context.router.push(const NamedRoute('SecondRoute')),
                    child: const Text('next'),
                  ),
                ),
              ),
            ),
          ),
          AutoRoute(
            path: '/second',
            page: PageInfo(
              'SecondRoute',
              builder: (_) => Builder(
                builder: (context) => Scaffold(
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('back'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      await tester.tap(find.byKey(const Key('field 0')));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.drag(find.byKey(const Key('field 3')), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_focusedField(), isNull);
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tap(find.text('next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'HomeRoute');
      expect(_focusedField(), isNull, reason: 'after tester.tap(find.text(back))');
      expect(tester.testTextInput.isVisible, isFalse, reason: 'after tester.tap(find.text(back))');
    },
    // A list too short to scroll closes the keyboard only where it bounces.
    variant: TargetPlatformVariant.only(.iOS),
  );
}

Key? _focusedField() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key;
