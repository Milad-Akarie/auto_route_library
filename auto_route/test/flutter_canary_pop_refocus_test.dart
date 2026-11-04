import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/145155
// (Navigator.pop gives focus back to a text field that wasn't focused when
// the page was opened).
// Setup, as in the Flutter report, without auto_route: a MaterialApp with a
// text field, a button that pushes a second page.
// Steps: tap the field, clear focus with FocusScope.unfocus, push the second
// page, pop it.
// Should: the field has no focus.
// Today, on Flutter 3.47.9 with material_ui 1.10.0: the field has focus
// again after the pop. If this test fails after a Flutter upgrade, Flutter
// fixed it: auto_route pages are plain Flutter routes, so apps get the fix
// too. Drop the canary and the item on the Flutter list.
void main() {
  testWidgets(
    'popping a page gives focus back to a text field that was unfocused when the page opened, until Flutter fixes flutter/flutter#145155',
    (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return Scaffold(body: TextField(focusNode: node));
            },
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(node.hasFocus, isTrue);
      FocusScope.of(context).unfocus();
      await tester.pump();
      expect(node.hasFocus, isFalse);

      final navigator = Navigator.of(context);
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('second'))));
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();

      // Flutter gives the field its focus back.
      expect(node.hasFocus, isTrue);
    },
  );
}
