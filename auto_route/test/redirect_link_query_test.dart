import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(page: _ShopRoute.page, path: '/shop'),
        RedirectRoute(path: '/store', redirectTo: '/shop?src=redirect'),
        RedirectRoute(path: '/outlet', redirectTo: '/shop'),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1721
  // A RedirectRoute can name query params in redirectTo, and the link's own
  // query params go along with them. Open '/store?color=red': the page should
  // read both src=redirect and color=red, and the url should show both.
  testWidgets('A redirect adds the link query params to those in redirectTo', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/store?color=red');
    expect(find.text('Shop color=red src=redirect'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/shop?src=redirect&color=red');
  });

  // The same redirect without a query in redirectTo keeps the link's query.
  testWidgets('A redirect keeps the link query params', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/outlet?color=blue');
    expect(find.text('Shop color=blue src=null'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/shop?color=blue');
  });
}

class _ShopRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'ShopRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text(
      'Shop color=${data.queryParams.optString('color') ?? 'null'} src=${data.queryParams.optString('src') ?? 'null'}',
    ),
  );
}
