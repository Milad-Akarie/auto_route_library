import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1803
// Setup: Android, a main page, page B and page C, each pushed on the one
// before. The reporter later traced the exit to
// android:enableOnBackInvokedCallback="true" in the manifest (a manifest
// line, which a headless test can't set); this test checks the part the
// package owns: what it tells Android about back.
// Steps: open C, open a dialog with showDialog, close the dialog, press
// system back.
// Happened: the app closed instead of showing B.
// Should: while C is on top Flutter tells Android it handles back, and the
// press shows B.
void main() {
  testWidgets(
    'back after closing a dialog shows the previous page',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('Main'), path: '/', initial: true),
          AutoRoute(page: _page('B'), path: '/b'),
          AutoRoute(page: _page('C'), path: '/c'),
        ],
      );
      addTearDown(router.dispose);
      final handlesBack = FrameworkHandlesBackRecorder()..listen(tester);
      await tester.pumpWidget(
        MaterialApp.router(theme: androidTheme, routerConfig: router.config()),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('B')));
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('C')));
      await tester.pumpAndSettle();

      showDialog<void>(
        context: tester.element(find.text('C')),
        builder: (_) => const AlertDialog(title: Text('Dialog')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsNothing);
      final afterDialog = handlesBack.isHandlingBack;

      await systemBack(tester);

      expect((afterDialog, handlesBack.isHandlingBack), (true, true));
      expectCurrentPage(router, 'B');
    },
    skip: kIsWeb,
    // Android only: on web Flutter never tells the platform whether it
    // handles back.
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
