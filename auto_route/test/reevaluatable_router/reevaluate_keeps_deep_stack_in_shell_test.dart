import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

PageInfo _shell(String name) => .new(name, builder: (_) => const AutoRouter());

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2190
// Setup, as reported: a main shell (guarded, the guard lets the user in)
// holding a home page with tabs Dashboard and Support; the Support tab is a
// stack of its own, to which pages are pushed (Faq, Category, Details).
// reevaluateListenable is set on the router.
// Steps: open the Support tab, push Faq, Category and Details on it, then fire
// reevaluateListenable while the guard still lets the user in.
// Should: the pushed stack stays: Details on top of Category, Faq and the
// Support index, at the same url.
void main() {
  testWidgets('Reevaluation that changes nothing keeps the pages pushed in a '
      'nested tab (#2190)', (tester) async {
    final notifier = ValueNotifier(0);
    addTearDown(notifier.dispose);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _shell('MainRoute'),
          path: '/main',
          guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
          children: [
            AutoRoute(
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const AutoTabsRouter(),
              ),
              path: 'home',
              initial: true,
              children: [
                AutoRoute(page: _page('DashboardRoute'), path: 'dashboard'),
                AutoRoute(
                  page: _shell('SupportRoute'),
                  path: 'support',
                  children: [
                    AutoRoute(page: _page('SupportIndex'), initial: true),
                    AutoRoute(page: _page('FaqRoute'), path: 'faq'),
                    AutoRoute(page: _page('CategoryRoute'), path: 'category'),
                    AutoRoute(page: _page('DetailsRoute'), path: 'details'),
                  ],
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
      initialLink: '/main/home/support',
      reevaluationNotifier: notifier,
    );
    final support = AutoRouter.of(tester.element(find.text('SupportIndex')));
    unawaited(support.push(const NamedRoute('FaqRoute')));
    await tester.pumpAndSettle();
    unawaited(support.push(const NamedRoute('CategoryRoute')));
    await tester.pumpAndSettle();
    unawaited(support.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    final names = support.stack.map((e) => e.routeData.name).toList();
    expect(names.lastOrNull, 'DetailsRoute');
    final url = router.urlState.url;

    notifier.value++;
    await tester.pumpAndSettle();

    expect(support.stack.map((e) => e.routeData.name), names);
    expect(find.text('DetailsRoute'), findsOneWidget);
    expect(router.urlState.url, url);
  });
}
