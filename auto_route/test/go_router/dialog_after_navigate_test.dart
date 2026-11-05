import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// The same scenario as flutter/flutter#146578 in go_router: on page B, a
// navigation back to page A, then showDialog or showModalBottomSheet with the
// root navigator's context, in the same frame. The dialog never shows.
//
// auto_route behaves the same, by Flutter's design, and these tests record
// it. A navigation changes the router's stack at once, but the Navigator
// applies the new pages when it next builds. A dialog opened before that
// goes on top of B, still the Navigator's top route, and Flutter's Navigator
// removes a page's dialogs and sheets along with the page. auto_route can't
// move them to another page. Opened once the navigation has landed, after
// the next frame, the dialog shows on A. A Navigator fed its pages directly
// behaves the same in both cases. go_router's maintainers labeled the report
// as a documentation issue.
//
// navigate() isn't awaited here: its future completes when the page it opens
// is popped (Milad-Akarie/auto_route_library#2154), so awaiting it would wait
// for A to close.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('ARoute', builder: (_) => const Text('ARoute')),
      ),
      AutoRoute(
        path: '/b',
        page: PageInfo('BRoute', builder: (_) => const Text('BRoute')),
      ),
    ],
  );

  final navigations = <String, void Function(StackRouter)>{
    'navigate': (router) => unawaited(router.navigatePath('/')),
    'replaceAll': (router) =>
        unawaited(router.replaceAll([const PageRouteInfo('ARoute')])),
  };

  final overlays = {
    'dialog': (
      find.byType(AlertDialog),
      (BuildContext context) {
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('Dialog')),
        );
      },
    ),
    'bottom sheet': (
      find.text('Sheet'),
      (BuildContext context) {
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => const Text('Sheet'),
        );
      },
    ),
  };

  for (final MapEntry(key: navigation, value: navigate)
      in navigations.entries) {
    for (final MapEntry(key: overlay, value: (finder, open))
        in overlays.entries) {
      for (final afterFrame in [false, true]) {
        // Steps: stack [ARoute, BRoute]; on BRoute call navigate or
        // replaceAll back to ARoute, then open a dialog or sheet with the
        // root navigator's context, in the same frame or after the next one.
        // Should: ARoute is the only page. In the same frame, the dialog or
        // sheet closes with BRoute; after the next frame, it shows on ARoute.
        final when = afterFrame ? 'after the next frame' : 'in the same frame';
        testWidgets(
          'a $overlay opened $when as $navigation ${afterFrame ? 'shows' : 'closes with the old page'}',
          (tester) async {
            final router = buildRouter();
            await pumpRouterApp(tester, router);
            unawaited(router.pushPath('/b'));
            await tester.pumpAndSettle();
            expectCurrentPage(router, 'BRoute');

            navigate(router);
            // pump(Duration.zero) runs the pending microtasks before the frame,
            // as the engine does; a bare pump() runs them after it when no frame
            // is scheduled yet, so the stack change would land a frame late.
            if (afterFrame) await tester.pump(.zero);
            open(router.navigatorKey.currentContext!);
            await tester.pumpAndSettle();

            expect(router.stack.map((page) => page.name), ['ARoute']);
            expect(find.text('ARoute'), findsOneWidget);
            expect(finder, afterFrame ? findsOneWidget : findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
