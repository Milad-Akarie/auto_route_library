import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  Widget book(RouteData<Object?> data) =>
      Scaffold(body: Text('book ${data.params.getInt('index')}'));

  // The router of the reporter's app: a book list, and a book page at
  // ':index' that zooms in over 400 ms, shown by a declarative router from
  // [index] (null shows the list alone).
  RootStackRouter booksRouter(
    ValueNotifier<int?> index, {
    required bool shouldUsePathAsKey,
  }) {
    const list = NamedRoute<void>('BookListRoute');
    return .build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'BooksRoute',
            builder: (_) => ValueListenableBuilder(
              valueListenable: index,
              builder: (_, shown, _) => AutoRouter.declarative(
                routes: (_) => [
                  list,
                  if (shown != null)
                    NamedRoute('BookDetailsRoute', params: {'index': shown}),
                ],
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'BookListRoute',
                builder: (_) => const Text('list'),
              ),
            ),
            CustomRoute(
              path: ':index',
              page: PageInfo('BookDetailsRoute', builder: book),
              transitionsBuilder: TransitionsBuilders.zoomIn,
              duration: const Duration(milliseconds: 400),
              usesPathAsKey: shouldUsePathAsKey,
            ),
          ],
        ),
      ],
    );
  }

  // How far the route that shows [text] has come in.
  double shownBy(WidgetTester tester, String text) =>
      ModalRoute.of(tester.element(find.text(text)))!.animation!.value;

  // #1256: in a declarative router, a book page replaced by another book page
  // (a new index) showed no transition. The answer in the thread: the two
  // pages are one route with one key, so set usesPathAsKey.
  // Steps: show book 0, let it settle, then show book 1; check half way.
  group('A page of the same route with a new path (#1256)', () {
    for (final usesPathAsKey in [true, false]) {
      testWidgets(
        usesPathAsKey
            ? 'zooms in as a new page with usesPathAsKey'
            : 'is the same page, updated in place, without usesPathAsKey',
        (tester) async {
          final index = ValueNotifier<int?>(0);
          addTearDown(index.dispose);
          await pumpRouterApp(
            tester,
            booksRouter(index, shouldUsePathAsKey: usesPathAsKey),
          );
          final atStart = find.text('book 0').evaluate().length;

          index.value = 1;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          final halfWay = shownBy(tester, 'book 1');
          await tester.pumpAndSettle();
          expect(
            (
              atStart,
              halfWay,
              find.text('book 0').evaluate().length,
              find.text('book 1').evaluate().length,
            ),
            (1, usesPathAsKey ? 0.5 : 1.0, 0, 1),
          );
        },
      );
    }
  });

  // #1256, a later report: in a nested router, replacing a page of a route
  // with usesPathAsKey by the same route with another path param did not
  // build the page again; navigating did.
  // Steps: '/dashboard' holds 'cms/table/:tableId', both with usesPathAsKey.
  // Open '/dashboard/cms/table/users', then replacePath() to
  // '/dashboard/cms/table/companies'.
  // Should: the table page shows companies, alone in the nested stack.
  testWidgets(
    'replacePath() to a new path param builds the nested page again (#1256)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/dashboard',
            usesPathAsKey: true,
            page: PageInfo(
              'DashboardRoute',
              builder: (_) => const AutoRouter(),
            ),
            children: [
              AutoRoute(
                path: 'cms/table/:tableId',
                usesPathAsKey: true,
                page: PageInfo(
                  'TableRoute',
                  builder: (data) =>
                      Text('table ${data.params.getString('tableId')}'),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        initialLink: '/dashboard/cms/table/users',
      );
      final atStart = find.text('table users').evaluate().length;

      unawaited(router.replacePath('/dashboard/cms/table/companies'));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>('DashboardRoute')!;
      expect(
        (
          atStart,
          find.text('table users').evaluate().length,
          find.text('table companies').evaluate().length,
          nested.stack
              .map((page) => page.routeData.params.get('tableId'))
              .join(),
          router.currentUrl,
        ),
        (1, 0, 1, 'companies', '/dashboard/cms/table/companies'),
      );
    },
  );
}
