import 'dart:async';

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
        AutoRoute(
          page: PageInfo('ProductRoute', builder: (_) => const AutoRouter()),
          path: '/product/:id',
          children: [
            AutoRoute(page: _page('ProductDetailsRoute'), path: '', initial: true),
            AutoRoute(
              page: PageInfo('ReviewHostRoute', builder: (_) => const AutoRouter()),
              path: 'review/:reviewId',
              children: [
                AutoRoute(page: _page('ReviewDetailsRoute'), path: '', initial: true),
                AutoRoute(page: _page('ReplyRoute'), path: 'reply'),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // flutter/flutter#121188: in go_router, pushNamed to a nested route had to
  // be given the ids of its parents again: they weren't carried forward. In
  // auto_route a page reads its parents' path params through
  // inheritedPathParams (@PathParam.inherit), so the route pushed names only
  // itself.
  // Steps: open '/product/5', then push ReviewHostRoute with reviewId 7 from
  // the product's nested router, then push ReplyRoute from the review's.
  // Should: each page reads id 5, the review pages reviewId 7, and the url
  // is '/product/5/review/7/reply'.
  testWidgets('A pushed child reads the path params of its parents', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/product/5');
    expect(find.text('ProductDetailsRoute id 5 reviewId null'), findsOneWidget);

    final product = router.innerRouterOf<StackRouter>('ProductRoute')!;
    unawaited(product.push(const NamedRoute('ReviewHostRoute', params: {'reviewId': '7'})));
    await tester.pumpAndSettle();
    expect(find.text('ReviewDetailsRoute id 5 reviewId 7'), findsOneWidget);
    expect(router.urlState.url, '/product/5/review/7');

    final review = product.innerRouterOf<StackRouter>('ReviewHostRoute')!;
    unawaited(review.push(const NamedRoute('ReplyRoute')));
    await tester.pumpAndSettle();
    expect(find.text('ReplyRoute id 5 reviewId 7'), findsOneWidget);
    expect(router.urlState.url, '/product/5/review/7/reply');
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (data) => Scaffold(
    body: Text(
      '$name id ${data.inheritedPathParams.optString('id') ?? 'null'} '
      'reviewId ${data.inheritedPathParams.optString('reviewId') ?? 'null'}',
    ),
  ),
);
