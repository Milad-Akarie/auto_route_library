import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _DashboardRoute.page,
          path: '/dashboard',
          initial: true,
          children: [
            AutoRoute(
              page: _VendorsRoute.page,
              path: 'vendors',
              initial: true,
              children: [
                AutoRoute(page: _VendorListRoute.page, path: ''),
                AutoRoute(
                  page: _EditVendorRoute.page,
                  path: ':vendor-id',
                  children: [AutoRoute(page: _VendorBranchesRoute.page, path: 'branches')],
                ),
              ],
            ),
          ],
        ),
        AutoRoute(page: _SettingsRoute.page, path: '/settings'),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1816
  // Open the vendor 'v-42' at '/dashboard/vendors/:vendor-id', push a page on
  // the root router over the dashboard, then call navigate(VendorBranchesRoute()).
  // The branches page should open under vendor 'v-42' and read its inherited
  // 'vendor-id', not fail to parse it from null at '/dashboard/vendors/:vendor-id/branches'.
  testWidgets('navigate() from outside the nested router keeps the inherited path params', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(
      router.navigate(
        _DashboardRoute(
          children: [
            _VendorsRoute(children: [_EditVendorRoute(vendorId: 'v-42')]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/dashboard/vendors/v-42');
    unawaited(router.push(const _SettingsRoute()));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    unawaited(router.navigate(const _VendorBranchesRoute()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Branches of v-42'), findsOneWidget);
    expect(router.urlState.url, '/dashboard/vendors/v-42/branches');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1816
  // Call navigate(VendorBranchesRoute()) right after opening the vendor 'v-42',
  // before its nested router is built. The branches page should still open
  // under vendor 'v-42'.
  testWidgets('navigate() before the parent is built keeps the inherited path params', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(
      router.navigate(
        _DashboardRoute(
          children: [
            _VendorsRoute(children: [_EditVendorRoute(vendorId: 'v-42')]),
          ],
        ),
      ),
    );
    // Let the router add the vendor page, which it does after checking guards.
    for (var i = 0; i < 5; i++) {
      await Future.microtask(() {});
    }

    unawaited(router.navigate(const _VendorBranchesRoute()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Branches of v-42'), findsOneWidget);
    expect(router.urlState.url, '/dashboard/vendors/v-42/branches');
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const _DashboardRoute({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = 'DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _VendorsRoute extends PageRouteInfo<void> {
  const _VendorsRoute({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = 'VendorsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _VendorListRoute extends PageRouteInfo<void> {
  const _VendorListRoute() : super(name);

  static const String name = 'VendorListRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Vendors'));
}

class _EditVendorRoute extends PageRouteInfo<void> {
  _EditVendorRoute({required String vendorId, List<PageRouteInfo>? children})
    : super(name, rawPathParams: {'vendor-id': vendorId}, initialChildren: children);

  static const String name = 'EditVendorRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      // As generated for a constructor parameter marked @PathParam('vendor-id').
      final vendorId = data.inheritedPathParams.getString('vendor-id');
      return Column(
        children: [
          Text('Vendor $vendorId'),
          const Expanded(child: AutoRouter()),
        ],
      );
    },
  );
}

class _VendorBranchesRoute extends PageRouteInfo<void> {
  const _VendorBranchesRoute() : super(name);

  static const String name = 'VendorBranchesRoute';
  static PageInfo page = PageInfo(
    name,
    // As generated for a constructor parameter marked @PathParam.inherit('vendor-id').
    builder: (data) => Text('Branches of ${data.inheritedPathParams.getString('vendor-id')}'),
  );
}

class _SettingsRoute extends PageRouteInfo<void> {
  const _SettingsRoute() : super(name);

  static const String name = 'SettingsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Settings'));
}
