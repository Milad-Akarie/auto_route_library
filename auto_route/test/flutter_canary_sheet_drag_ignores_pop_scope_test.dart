import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/152120:
// dragging a modal bottom sheet down closes it even when a
// PopScope(canPop: false) inside it blocks pops, and the PopScope hears
// didPop: true.
// Setup, without auto_route: a page that shows a modal bottom sheet whose
// content is wrapped in PopScope(canPop: false).
// Steps: drag the sheet down past its height.
// Should: the sheet stays, and the PopScope hears didPop: false, as for the
// back button.
// Today, on Flutter 3.47.9 with material_ui 1.10.0: the sheet's onClosing
// calls Navigator.pop, which pops whatever the PopScope says
// (material_ui lib/src/bottom_sheet.dart:768-772,
// `_ModalBottomSheetState.build`); the maintainer in the thread names that
// call. Navigator.maybePop would respect the PopScope.
// A sheet in an auto_route app is the same pageless route on the router's
// navigator. If this test fails after a Flutter upgrade, the drag now
// respects PopScope: drop this canary.
void main() {
  testWidgets(
    'dragging a sheet down closes it through PopScope(canPop: false), until '
    'Flutter fixes flutter/flutter#152120',
    (tester) async {
      final heard = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, _) => heard.add(didPop),
                    child: const SizedBox(
                      height: 300,
                      child: Center(child: Text('sheet')),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('sheet'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
      expect(heard, [true]);
    },
    // material_ui 1.10.0 makes a CurvedAnimation on every drag end of a modal
    // sheet and never disposes it (lib/src/bottom_sheet.dart:744,
    // `_ModalBottomSheetState.handleDragEnd`), a Flutter leak of its own.
    experimentalLeakTesting: LeakTesting.settings.withIgnored(
      classes: ['CurvedAnimation'],
    ),
  );
}
