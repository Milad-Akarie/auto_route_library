import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  late List<String> pushes;
  setUp(() {
    pushes = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          initial: true,
          path: '/dashboard',
          page: const EmptyShellRoute('dashboard'),
          children: [
            AutoRoute(initial: true, page: _dashboardPage),
            AutoRoute(
              path: 'cashless',
              page: const EmptyShellRoute('cashless'),
              children: [
                AutoRoute(page: _page('CashlessSchoolMainRoute')),
                AutoRoute(page: _page('CashlessHistoryRoute')),
                AutoRoute(initial: true, page: _page('CashlessSchoolApplyRoute')),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2323
  // '/dashboard' is an EmptyShellRoute holding the dashboard page and the
  // 'cashless' EmptyShellRoute, whose initial page is CashlessSchoolApplyRoute.
  // From the dashboard page, push the cashless route, then go back.
  // The reporter's logger showed "Prev: Root" for the apply page and
  // reported that back can't return to the dashboard. The apply page is the
  // first page of the cashless shell's own navigator, so that navigator
  // reports no previous route, as every Flutter Navigator does for its first
  // route. Back still returns to the dashboard.
  for (final back in ['system back', 'back button']) {
    testWidgets('$back from the first page of a nested shell returns to the dashboard', (tester) async {
      await pumpRouterConfigApp(tester, router.config(navigatorObservers: () => [_PushRecorder(pushes)]));
      expect(find.text('DashboardRoute'), findsOneWidget);

      await tester.tap(find.text('Open cashless'));
      await tester.pumpAndSettle();
      expect(find.text('CashlessSchoolApplyRoute'), findsOneWidget);
      expect(router.currentPath, '/dashboard/cashless');
      expect(pushes, [
        'dashboard after null',
        'DashboardRoute after null',
        'cashless after DashboardRoute',
        'CashlessSchoolApplyRoute after null',
      ]);

      if (back == 'system back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byType(BackButton));
      }
      await tester.pumpAndSettle();
      expect(find.text('DashboardRoute'), findsOneWidget, reason: 'after tester.tap(find.byType(BackButton))');
      expect(router.currentPath, '/dashboard');
    });
  }

  // Pushing a page inside the cashless shell, then going back twice,
  // returns to its first page, then to the dashboard.
  testWidgets('back from a page pushed inside the nested shell returns to the dashboard', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await tester.tap(find.text('Open cashless'));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('CashlessHistoryRoute')));
    await tester.pumpAndSettle();
    expect(find.text('CashlessHistoryRoute'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('CashlessSchoolApplyRoute'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('DashboardRoute'), findsOneWidget);
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    body: Text(name),
  ),
);

final _dashboardPage = PageInfo('DashboardRoute', builder: (_) => const _DashboardPage());

class _DashboardPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('DashboardRoute'),
        TextButton(
          onPressed: () => context.router.push(const NamedRoute('cashless')),
          child: const Text('Open cashless'),
        ),
      ],
    );
  }
}

class _PushRecorder extends AutoRouterObserver {
  new(this.pushes);

  final List<String> pushes;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    pushes.add('${route.settings.name ?? 'null'} after ${previousRoute?.settings.name ?? 'null'}');
  }
}
