import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Back from the first page of a nested shell returns to the dashboard.
// https://github.com/Milad-Akarie/auto_route_library/issues/2323
// Headless test: auto_route/test/nested_router/nested_shell_back_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  RootStackRouter buildRouter() => .build(
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
              AutoRoute(initial: true, page: _page('CashlessSchoolApplyRoute')),
            ],
          ),
        ],
      ),
    ],
  );

  // Steps: from the dashboard page, push the 'cashless' EmptyShellRoute,
  // whose initial page is CashlessSchoolApplyRoute, then go back.
  // Should: the apply page's own navigator reports no previous route, as
  // every Flutter Navigator does for its first route, and back returns to
  // the dashboard at '/dashboard'.
  for (final back in ['system back', 'back button']) {
    testWidgets(
      '$back from the first page of a nested shell returns to the dashboard',
      (tester) async {
        final pushes = <String>[];
        final router = buildRouter();
        await pumpRouterConfigApp(
          tester,
          router.config(
            deepLinkBuilder: (link) =>
                link.initial ? const DeepLink.path('/dashboard') : link,
            navigatorObservers: () => [_PushRecorder(pushes)],
          ),
        );
        expect(find.text('DashboardRoute'), findsOneWidget);

        await tester.tap(find.text('Open cashless'));
        await tester.pumpAndSettle();
        expect(find.text('CashlessSchoolApplyRoute'), findsOneWidget);
        expect(pushes.lastOrNull, 'CashlessSchoolApplyRoute after null');
        await expectBrowserUrl('/dashboard/cashless');

        if (back == 'system back') {
          await systemBack(tester);
        } else {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        expect(find.text('DashboardRoute'), findsOneWidget);
        expect(router.currentPath, '/dashboard');
        await expectBrowserUrl('/dashboard');
      },
    );
  }
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    body: Center(child: Text(name)),
  ),
);

final _dashboardPage = PageInfo(
  'DashboardRoute',
  builder: (_) => const _DashboardPage(),
);

class _DashboardPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('DashboardRoute'),
          TextButton(
            onPressed: () => context.router.push(const NamedRoute('cashless')),
            child: const Text('Open cashless'),
          ),
        ],
      ),
    );
  }
}

class _PushRecorder extends AutoRouterObserver {
  new(this.pushes);

  final List<String> pushes;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    pushes.add(
      '${route.settings.name ?? 'null'} after '
      '${previousRoute?.settings.name ?? 'null'}',
    );
  }
}
