import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter issue https://github.com/flutter/flutter/issues/92873:
// a PageStorage above the app can't be read from a page.
// Setup: one PageStorage around MaterialApp, holding a value; a page reads
// PageStorage.maybeOf(context). The same with MaterialApp.router and an
// auto_route router.
// Steps: show the first page and read the bucket it finds.
// Today every ModalRoute wraps its page in a PageStorage of its own
// (widgets/routes.dart, _ModalScopeState.build), so the page finds its
// route's empty bucket and never the app's. auto_route pages are ModalRoutes,
// so an auto_route app sees the same. Flutter keeps it open (P2) with no
// opt-out; the thread asks for one.
// If this test fails after a Flutter upgrade, a page can now reach a
// PageStorage above its navigator: drop this canary.
void main() {
  testWidgets('a plain page reads its route bucket', (tester) async {
    final appBucket = PageStorageBucket();
    PageStorageBucket? found;
    await tester.pumpWidget(
      PageStorage(
        bucket: appBucket,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              found = PageStorage.maybeOf(context);
              return const Text('Home');
            },
          ),
        ),
      ),
    );

    expect(found, isNotNull);
    expect(identical(found, appBucket), isFalse);
  });

  testWidgets('an auto_route page reads its route bucket', (tester) async {
    final appBucket = PageStorageBucket();
    PageStorageBucket? found;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => Builder(
              builder: (context) {
                found = PageStorage.maybeOf(context);
                return const Text('Home');
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      PageStorage(
        bucket: appBucket,
        child: MaterialApp.router(routerConfig: router.config()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(found, isNotNull);
    expect(identical(found, appBucket), isFalse);
  });
}
