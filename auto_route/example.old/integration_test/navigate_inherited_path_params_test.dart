import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigate() to a nested route keeps the path params it inherits.
// https://github.com/Milad-Akarie/auto_route_library/issues/1816
// Headless test:
// auto_route/test/nested_router/navigate_inherited_path_params_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('navigate inherited path params', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _DashboardRoute.page,
            path: '/',
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
                    children: [
                      AutoRoute(
                        page: _VendorBranchesRoute.page,
                        path: 'branches',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          AutoRoute(page: _SettingsRoute.page, path: '/settings'),
        ],
      );
    });

    // Steps: open the vendor 'v-42' at '/vendors/:vendor-id', push a page on
    // the root router over it, then call navigate(VendorBranchesRoute()).
    // Should: the branches page opens under vendor 'v-42' at
    // '/vendors/v-42/branches', not fail to parse 'vendor-id' from null.
    testWidgets(
      'navigate() from outside the nested router keeps the inherited path '
      'params',
      (tester) async {
        await pumpRouterAppWithConfig(tester, router);
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
        expect(find.text('Vendor v-42'), findsOneWidget);
        await expectBrowserUrl('/vendors/v-42');
        unawaited(router.push(const _SettingsRoute()));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);

        unawaited(router.navigate(const _VendorBranchesRoute()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Branches of v-42'), findsOneWidget);
        expect(router.urlState.url, '/vendors/v-42/branches');
        await expectBrowserUrl('/vendors/v-42/branches');
      },
    );
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(name, initialChildren: children);

  static const String name = 'DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _VendorsRoute extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(name, initialChildren: children);

  static const String name = 'VendorsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _VendorListRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'VendorListRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Vendors')),
  );
}

class _EditVendorRoute extends PageRouteInfo<void> {
  new({required String vendorId, List<PageRouteInfo>? children})
    : super(
        name,
        rawPathParams: {'vendor-id': vendorId},
        initialChildren: children,
      );

  static const String name = 'EditVendorRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      // As generated for a constructor parameter marked
      // @PathParam('vendor-id').
      final vendorId = data.inheritedPathParams.getString('vendor-id');
      return Scaffold(
        body: Column(
          children: [
            Text('Vendor $vendorId'),
            const Expanded(child: AutoRouter()),
          ],
        ),
      );
    },
  );
}

class _VendorBranchesRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'VendorBranchesRoute';
  static PageInfo page = PageInfo(
    name,
    // As generated for a constructor parameter marked
    // @PathParam.inherit('vendor-id').
    builder: (data) =>
        Text('Branches of ${data.inheritedPathParams.getString('vendor-id')}'),
  );
}

class _SettingsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'SettingsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Settings')),
  );
}
