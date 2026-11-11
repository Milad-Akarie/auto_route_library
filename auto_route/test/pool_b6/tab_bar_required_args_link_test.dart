import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2107
// A thin report: a video and a sample repo that is gone from the thread. The
// reporter shows AutoTabsRouter.tabBar with a second tab, TabRoute2, whose
// page has a required constructor parameter, on web. Opened the first time,
// it works; after a browser refresh the error "TabRoute2Args can not be null
// because the corresponding page has a required parameter" shows. Assumed
// from the title and the error: the tab's routes list gives TabRoute2 its
// argument, and the refresh opens the tab's url '/tab2', which holds
// no argument. #1302, which the reporter links, is not in the thread.
// Steps: (1) open the app and switch to the second tab, (2) start the app on
// the url '/tab2', which a refresh does, (3) the same with the value as a
// path parameter, (4) go to '/tab2' while the app runs.
// Result: (1) shows the argument. (2) and (4) threw
// MissingRequiredParameterError, as a url can't hold a constructor argument.
// The tab's routes list holds it, so they now show the argument from there.
// (3) shows the value from the url. A tab whose routes list has no argument
// still reports it.
void main() {
  RootStackRouter buildRouter({bool isTab2ArgListed = true}) => .build(
    routes: [
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        initial: true,
        builder: (_, _) => AutoTabsRouter.tabBar(
          routes: [
            const NamedRoute('TabRoute1'),
            NamedRoute(
              'TabRoute2',
              args: isTab2ArgListed ? 'from routes' : null,
            ),
            const NamedRoute('TabRoute3', params: {'name': 'from routes'}),
          ],
          builder: (_, child, controller) => Column(
            children: [
              Expanded(child: child),
              TextButton(
                onPressed: () => controller.animateTo(1),
                child: const Text('go to tab 2'),
              ),
            ],
          ),
        ),
        children: [
          NamedRouteDef(
            name: 'TabRoute1',
            path: 'tab1',
            initial: true,
            builder: (_, _) => const Text('Tab 1'),
          ),
          NamedRouteDef(
            name: 'TabRoute2',
            path: 'tab2',
            builder: (_, data) => Text('Tab 2 ${data.argsAs<String>()}'),
          ),
          NamedRouteDef(
            name: 'TabRoute3',
            path: 'tab3/:name',
            builder: (_, data) =>
                Text('Tab 3 ${data.inheritedPathParams.getString('name')}'),
          ),
        ],
      ),
    ],
  );

  testWidgets('A tab with a required argument shows it after a tab switch', (
    tester,
  ) async {
    await pumpRouterApp(tester, buildRouter());

    await tester.tap(find.text('go to tab 2'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tab 2 from routes'), findsOneWidget);
  });

  testWidgets('A refresh on the url of a tab with a required constructor '
      "argument shows the argument from the tab's routes list", (tester) async {
    await pumpRouterApp(tester, buildRouter(), initialLink: '/tab2');

    expect(tester.takeException(), isNull);
    expect(find.text('Tab 2 from routes'), findsOneWidget);
  });

  testWidgets('A link to a tab with a required constructor argument while the '
      "app runs shows the argument from the tab's routes list", (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);

    unawaited(router.navigatePath('/tab2'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tab 2 from routes'), findsOneWidget);
  });

  testWidgets('A refresh on the url of a tab whose routes list has no argument '
      'reports the missing argument', (tester) async {
    await pumpRouterApp(
      tester,
      buildRouter(isTab2ArgListed: false),
      initialLink: '/tab2',
    );

    expect(tester.takeException(), isA<MissingRequiredParameterError>());
  });

  testWidgets('A refresh on the url of a tab with a path parameter shows it', (
    tester,
  ) async {
    await pumpRouterApp(tester, buildRouter(), initialLink: '/tab3/sam');

    expect(tester.takeException(), isNull);
    expect(find.text('Tab 3 sam'), findsOneWidget);
  });
}
