import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#62023: a widget that listens to route changes, shown in a
// dialog. In Flutter, a RouteObserver<PageRoute> threw for the dialog's
// route. In auto_route, a widget with AutoRouteAwareStateMixin threw
// 'RouteData operation requested with a context that does not include an
// RouteData' as soon as a dialog showed it: the dialog is not a page and
// has no route data to subscribe to.
// Steps: an app with an AutoRouteObserver opens a dialog, with showDialog or
// showGeneralDialog, that shows the widget, then closes it.
// Should: the widget shows and nothing throws.
void main() {
  final opens = <String, void Function(BuildContext)>{
    'showDialog': (context) => showDialog<void>(context: context, builder: (_) => const _AwareText()),
    'showGeneralDialog': (context) =>
        showGeneralDialog<void>(context: context, pageBuilder: (_, _, _) => const _AwareText()),
  };

  for (final MapEntry(key: name, value: open) in opens.entries) {
    testWidgets('a route aware widget in a dialog opened by $name shows without throwing', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
          ),
        ],
      );
      await pumpRouterApp(tester, router, observers: () => [AutoRouteObserver()]);

      open(router.navigatorKey.currentContext!);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Aware'), findsOneWidget);

      router.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Aware'), findsNothing);
    });
  }
}

class _AwareText extends StatefulWidget {
  const _AwareText();

  @override
  State<_AwareText> createState() => _AwareTextState();
}

class _AwareTextState extends State<_AwareText> with AutoRouteAwareStateMixin<_AwareText> {
  @override
  Widget build(BuildContext context) => const Text('Aware');
}
