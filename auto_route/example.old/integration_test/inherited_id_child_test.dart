import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A child route reads the path param it inherits from its parent.
// https://github.com/Milad-Akarie/auto_route_library/issues/2209
// Headless test: auto_route/test/nested_router/inherited_id_child_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _ListDetailRouter.page,
          path: '/details',
          children: [
            AutoRoute(
              page: _ListDetailRoute.page,
              initial: true,
              path: ':id',
              children: [
                AutoRoute(page: _CreateListItemsRoute.page, path: ':familyId'),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // Steps: open the list 'l-1' at '/details/:id', then push
  // CreateListItemsRoute(familyId: 'f-1') from it.
  // Should: the page reads the inherited id 'l-1', and the url, and on web the
  // address bar, is '/details/l-1/f-1'.
  testWidgets(
    'A child route reads the id it inherits when pushed from its parent',
    (tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(
        router.navigate(
          _ListDetailRouter(children: [_ListDetailRoute(id: 'l-1')]),
        ),
      );
      await tester.pumpAndSettle();
      final detail = tester.element(find.text('List l-1'));

      unawaited(detail.router.push(_CreateListItemsRoute(familyId: 'f-1')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Create f-1 in l-1'), findsOneWidget);
      expect(router.urlState.url, '/details/l-1/f-1');
      await expectBrowserUrl('/details/l-1/f-1');
    },
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'HomeRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const Text('Home'));
}

class _ListDetailRouter extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(pageName, initialChildren: children);

  static const String pageName = 'ListDetailRouter';
  static PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

class _ListDetailRoute extends PageRouteInfo<void> {
  new({required String id, List<PageRouteInfo>? children})
    : super(pageName, rawPathParams: {'id': id}, initialChildren: children);

  static const String pageName = 'ListDetailRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Column(
      children: [
        Text('List ${data.inheritedPathParams.getString('id')}'),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _CreateListItemsRoute extends PageRouteInfo<void> {
  new({required String familyId})
    : super(pageName, rawPathParams: {'familyId': familyId});

  static const String pageName = 'CreateListItemsRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      return Text(
        'Create ${pathParams.getString('familyId')} in '
        '${pathParams.getString('id')}',
      );
    },
  );
}
