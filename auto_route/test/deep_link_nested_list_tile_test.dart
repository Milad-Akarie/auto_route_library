import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/169030
  // Reported for go_router: a page inside a shell whose content is a bare
  // ListTile showed a blank screen when its url was typed, though not when
  // it was reached by a tap. A Text in place of the ListTile showed fine.
  // Steps: a shell page, a Scaffold around a tabs router whose tab holds a
  // stack router of '' and 'bug', each page a bare ListTile. Open the app at
  // /test/bug, and in another run at /test and tap through to /test/bug.
  // Should: the 'bug' ListTile shows both ways, with no error.
  for (final byLink in [true, false]) {
    final how = byLink ? 'by its url' : 'by a tap';
    testWidgets('A ListTile page in a shell shows when opened $how', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'ShellRoute',
            path: '/',
            builder: (context, _) => Scaffold(
              body: GestureDetector(
                onTap: () => context.router.navigatePath('/test/bug'),
                child: const AutoTabsRouter(routes: [NamedRoute('TestTab')]),
              ),
            ),
            children: [
              NamedRouteDef.shell(
                name: 'TestTab',
                path: 'test',
                children: [
                  NamedRouteDef(
                    name: 'HelloRoute',
                    path: '',
                    builder: (_, _) =>
                        const ListTile(title: Text('Hello World')),
                  ),
                  NamedRouteDef(
                    name: 'BugRoute',
                    path: 'bug',
                    builder: (_, _) => const ListTile(title: Text('bug')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        initialLink: byLink ? '/test/bug' : '/test',
      );
      if (!byLink) {
        await tester.tap(find.text('Hello World'));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(router.currentUrl, '/test/bug');
      expect(find.widgetWithText(ListTile, 'bug'), findsOneWidget);
      expect(find.text('bug').hitTestable(), findsOneWidget);
    });
  }
}
