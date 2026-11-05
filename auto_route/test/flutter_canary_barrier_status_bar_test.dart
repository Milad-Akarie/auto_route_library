import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/24969: a
// dialog's modal barrier dims the page but not the status bar, which keeps
// the page's color, unlike native Android dialogs.
// Setup, without auto_route: a page whose AppBar asks for a red status bar.
// Steps: show a dialog with the default black barrier.
// Should: the status bar is dimmed with the page.
// Today, on Flutter 3.47.9 with material_ui 1.10.0: the barrier
// (flutter/lib/src/widgets/routes.dart:2273-2290, `_buildModalBarrier`)
// paints only inside the app and adds no SystemUiOverlayStyle annotation, so
// the style the platform reads at the top of the screen stays the AppBar's
// red. The thread's workaround (an AnnotatedRegion around the dialog) is the
// app's.
// A dialog-style route in auto_route (a CustomRoute with a barrierColor, or
// showDialog from a page) is the same ModalRoute. If this test fails after a
// Flutter upgrade, Flutter now tints the status bar under a barrier: drop
// this canary.
void main() {
  testWidgets(
    'the status bar keeps the page color under a dialog barrier, until '
    'Flutter fixes flutter/flutter#24969',
    (tester) async {
      // The style the platform reads at the top of the screen.
      Color? statusBarColor() {
        final layer = tester.binding.renderViews.firstOrNull?.debugLayer;
        final style = layer?.find<SystemUiOverlayStyle>(const Offset(400, 1));
        return style?.statusBarColor;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Color(0xFFFF0000),
              ),
            ),
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(title: Text('dialog')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      final beforeDialog = statusBarColor();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);
      expect(
        (beforeDialog, statusBarColor()),
        (const Color(0xFFFF0000), const Color(0xFFFF0000)),
      );
    },
  );
}
