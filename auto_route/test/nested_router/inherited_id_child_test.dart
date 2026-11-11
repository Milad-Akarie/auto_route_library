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

  // https://github.com/Milad-Akarie/auto_route_library/issues/2209
  // Open the list 'l-1' at '/details/:id', then push
  // CreateListItemsRoute(familyId: 'f-1'), whose page also reads
  // @PathParam.inherit('id'). It should read 'l-1', not fail to parse 'id'
  // from null.
  testWidgets(
    'A child route reads the id it inherits when pushed from its parent',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
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
    },
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2209#issuecomment-3377835773
  // The same through router.navigate() from the root router.
  testWidgets(
    'A child route reads the id it inherits when navigated to from the root',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(
        router.navigate(
          _ListDetailRouter(children: [_ListDetailRoute(id: 'l-1')]),
        ),
      );
      await tester.pumpAndSettle();

      unawaited(router.navigate(_CreateListItemsRoute(familyId: 'f-2')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Create f-2 in l-1'), findsOneWidget);
      expect(router.urlState.url, '/details/l-1/f-2');
    },
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2209
  // The same from a deep link to '/details/l-1/f-3'.
  testWidgets('A child route reads the id it inherits from a deep link', (
    tester,
  ) async {
    await pumpRouterApp(tester, router, initialLink: '/details/l-1/f-3');
    expect(tester.takeException(), isNull);
    expect(find.text('Create f-3 in l-1'), findsOneWidget);
  });
}

abstract final class _HomeRoute {
  static const String pageName = 'HomeRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (_) => const Text('Home'),
  );
}

class _ListDetailRouter extends PageRouteInfo<void> {
  const new({required List<PageRouteInfo> children})
    : super(pageName, initialChildren: children);

  static const String pageName = 'ListDetailRouter';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (_) => const AutoRouter(),
  );
}

class _ListDetailRoute extends PageRouteInfo<void> {
  new({required String id}) : super(pageName, rawPathParams: {'id': id});

  static const String pageName = 'ListDetailRoute';
  static final PageInfo page = PageInfo(
    pageName,
    // As generated for a constructor parameter marked @PathParam('id').
    builder: (data) => Column(
      children: [
        Text('List ${data.inheritedPathParams.getString('id')}'),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _CreateListItemsRoute extends PageRouteInfo<void> {
  // As generated: only the route's own path param goes in rawPathParams.
  new({required String familyId})
    : super(pageName, rawPathParams: {'familyId': familyId});

  static const String pageName = 'CreateListItemsRoute';
  static final PageInfo page = PageInfo(
    pageName,
    // As generated for @PathParam('familyId') and @PathParam.inherit('id').
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      return Text(
        'Create ${pathParams.getString('familyId')} in '
        '${pathParams.getString('id')}',
      );
    },
  );
}
