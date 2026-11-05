import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bugs https://github.com/flutter/flutter/issues/154719
// and https://github.com/flutter/flutter/issues/166665 (a tap right after an
// iOS swipe back isn't recognized) and
// https://github.com/flutter/flutter/issues/188840 (a scroll right after the
// release isn't recognized).
// Setup, as in the Flutter reports, without auto_route: iOS, a home page with
// a button and a ListView, a CupertinoPage-style second page pushed over it.
// Steps: swipe back from the left edge, let go past the halfway point, and
// 250 ms later tap the button, or drag the list.
// Should: the home page takes the tap, and the drag.
// Today, on Flutter 3.47.9 with material_ui 1.10.0: neither is recognized
// until the release animation ends. If a test fails after a Flutter upgrade, Flutter changed how input
// reaches the page under a closing route: RouteType.cupertino pages in
// auto_route follow it.
void main() {
  late int taps;
  late ScrollController controller;

  Future<void> pumpAndSwipeBack(WidgetTester tester) async {
    taps = 0;
    controller = ScrollController();
    addTearDown(controller.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: .iOS),
        home: Builder(
          builder: (c) {
            context = c;
            return Scaffold(
              body: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => taps++,
                      child: const Text('tap'),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        for (var i = 0; i < 50; i++)
                          SizedBox(
                            height: 80,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('item $i'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('second')),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(2, 300));
    await gesture.moveBy(const Offset(500, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('tap'), findsOneWidget);
  }

  testWidgets('a tap 250 ms after an iOS swipe back is not recognized, until Flutter fixes '
      'flutter/flutter#154719 and #166665', (tester) async {
    await pumpAndSwipeBack(tester);
    await tester.tap(find.text('tap'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 0);

    // The control: once the animation is over, the button works.
    await tester.tap(find.text('tap'));
    expect(taps, 1);
  });

  testWidgets('a drag 250 ms after an iOS swipe back does not scroll the list, until Flutter fixes '
      'flutter/flutter#188840', (tester) async {
    await pumpAndSwipeBack(tester);
    await tester.drag(
      find.text('item 3'),
      const Offset(0, -200),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(controller.offset, 0.0);
    await tester.pumpAndSettle();

    // The control: once the animation is over, the list scrolls.
    await tester.drag(find.text('item 3'), const Offset(0, -200));
    expect(controller.offset, greaterThan(0));
  });
}
