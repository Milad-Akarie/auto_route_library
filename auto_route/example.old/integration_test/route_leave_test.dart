import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/route_leave_router.dart';

// An AutoRouteLeaveListener in a page hears each time the page is left, once,
// with how: popped, covered, replaced or removed. A back its PopScope refuses
// isn't reported.
// flutter/flutter#145079 and flutter/flutter#137394 (go_router's onExit).
// Headless test: auto_route/test/route_leave_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late List<RouteLeaveKind> leaves;
  late ValueNotifier<bool> editorCanPop;
  late RootStackRouter router;

  setUp(() {
    leaves = [];
    editorCanPop = ValueNotifier(true);
    router = buildRouteLeaveRouter(leaves: leaves, editorCanPop: editorCanPop);
  });
  tearDown(() => editorCanPop.dispose());

  Future<void> openEditor(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/editor'));
    await tester.pumpAndSettle();
    expect(find.text('Editor'), findsOneWidget);
  }

  // Steps: open the editor, refuse pops, press system back; allow pops,
  // press system back again.
  // Should: the refused back reports nothing, the second reports popped.
  testWidgets('system back reports popped, unless the PopScope refuses it', (
    tester,
  ) async {
    await openEditor(tester);
    editorCanPop.value = false;
    await tester.pump();
    await systemBack(tester);
    expect(leaves, isEmpty);
    expect(find.text('Editor'), findsOneWidget);

    editorCanPop.value = true;
    await tester.pump();
    await systemBack(tester);
    expect(leaves, [RouteLeaveKind.popped]);
    expect(find.text('Home'), findsOneWidget);
  });

  // Steps: open the editor, push the preview, then pop it and replace the
  // editor with the preview.
  // Should: covered, then replaced.
  testWidgets('a push over the page reports covered, a replace replaced', (
    tester,
  ) async {
    await openEditor(tester);
    unawaited(router.pushPath('/preview'));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered]);

    router.pop();
    await tester.pumpAndSettle();
    unawaited(router.replacePath('/preview'));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered, RouteLeaveKind.replaced]);
    await expectBrowserUrl('/preview');
  });

  // Steps: open the editor, navigate to '/'.
  // Should: removed.
  testWidgets('navigating to the page below reports removed', (tester) async {
    await openEditor(tester);
    unawaited(router.navigatePath('/'));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.removed]);
    expect(find.text('Home'), findsOneWidget);
    await expectBrowserUrl('/');
  });
}
