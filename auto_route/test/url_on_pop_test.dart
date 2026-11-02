import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2311
  // Steps: an AutoTabsRouter tab holds a list page and a shell route
  // 'patient/:patientId' that has an optional query param ('source', left
  // null). Push the shell route (url '/patients/patient/p-123'), then tap the
  // back button, which calls context.maybePop().
  // Happens: the list page shows again but the reported url stays
  // '/patients/patient/p-123'.
  // Should: the reported url goes back to '/patients'.
  testWidgets(
    'Popping a shell route with path params inside AutoTabsRouter reverts the reported url',
    (WidgetTester tester) async {
      final router = RootStackRouter.build(routes: [
        AutoRoute(page: _TabsHostRoute.page, path: '/', initial: true, children: [
          AutoRoute(page: _PatientsShellRoute.page, path: 'patients', children: [
            AutoRoute(page: _PatientsListRoute.page, path: '', initial: true),
            AutoRoute(page: _PatientShellRoute.page, path: 'patient/:patientId', children: [
              AutoRoute(page: _PatientInfoRoute.page, path: '', initial: true),
            ]),
          ]),
        ]),
      ]);
      await pumpRouterConfigApp(tester, router.config());
      expect(router.urlState.url, '/patients');

      await tester.tap(find.text('Push patient'));
      await tester.pumpAndSettle();
      expect(find.text(_PatientInfoRoute.name), findsOneWidget);
      expect(router.urlState.url, '/patients/patient/p-123');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(_PatientsListRoute.name), findsOneWidget);
      expect(router.urlState.url, '/patients');
    },
  );
}

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const AutoTabsRouter(routes: [_PatientsShellRoute()]),
  );
}

class _PatientsShellRoute extends PageRouteInfo<void> {
  const _PatientsShellRoute() : super(name);

  static const String name = '_PatientsShellRoute';
  static PageInfo page = PageInfo.emptyShell(name);
}

class _PatientShellRoute extends PageRouteInfo<void> {
  _PatientShellRoute({required String patientId})
      : super(name, rawPathParams: {'patientId': patientId}, rawQueryParams: {'source': null});

  static const String name = '_PatientShellRoute';
  static PageInfo page = PageInfo.emptyShell(name);
}

class _PatientsListRoute extends PageRouteInfo<void> {
  const _PatientsListRoute() : super(name);

  static const String name = '_PatientsListRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: Column(children: [
          const Text(name),
          TextButton(
            onPressed: () => context.pushRoute(_PatientShellRoute(patientId: 'p-123')),
            child: const Text('Push patient'),
          ),
        ]),
      ),
    ),
  );
}

class _PatientInfoRoute extends PageRouteInfo<void> {
  const _PatientInfoRoute() : super(name);

  static const String name = '_PatientInfoRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.maybePop())),
        body: const Text(name),
      ),
    ),
  );
}
