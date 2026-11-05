import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/64727:
// on web, the browser tab's title is wrong after the back button.
// Setup, without auto_route: a Navigator built from pages, each page under a
// Title widget with its own title, as an auto_route app gives each page.
// Steps: push the second page, then pop it.
// Today: Title sends its title to the platform only when it builds, and the
// first page does not build again when it shows again, so the title of the
// page that was left stays. auto_route builds pages through the same
// Navigator, so its apps see the same in the browser tab (checked in Chrome
// with auto_route: after back to P1, document.title was still P2's).
// Apps can rebuild their Title when the page shows again: a page that reads
// ModalRoute.of(context) builds again when it becomes the top route.
// If this test fails after a Flutter upgrade, Flutter now restores the
// title on pop: drop this canary and the note above.
void main() {
  testWidgets(
    'popping a page leaves the title of the page left, until the page under it builds',
    (tester) async {
      final titles = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
            titles.add(
              (call.arguments as Map<Object?, Object?>)['label']! as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      Page<void> page(String name) => MaterialPage(
        key: ValueKey(name),
        child: Title(
          color: const Color(0xFF000000),
          title: name,
          child: Text(name),
        ),
      );
      var pages = [page('First')];
      late StateSetter setPages;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setPages = setState;
              return Navigator(
                pages: List.of(pages),
                onDidRemovePage: (removed) =>
                    setState(() => pages = [...pages]..remove(removed)),
              );
            },
          ),
        ),
      );
      setPages(() => pages = [...pages, page('Second')]);
      await tester.pumpAndSettle();
      expect(titles.lastOrNull, 'Second');

      setPages(() => pages = pages.take(1).toList());
      await tester.pumpAndSettle();
      expect(find.text('First'), findsOneWidget);
      expect(
        titles.lastOrNull,
        'Second',
        reason: 'after setPages(() => pages = pages.take(1).toList())',
      );
    },
  );
}
