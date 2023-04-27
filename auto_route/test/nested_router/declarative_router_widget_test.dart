import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

void main() {
  late NestedRouter router;
  setUp(() {
    router = NestedRouter();
  });

  testWidgets('Simple Declarative routing test', (WidgetTester tester) async {
    final pageNotifier = ValueNotifier(1);
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (_) => DeepLink.single(
          DeclarativeRouterHostRoute(pageNotifier: pageNotifier),
        ),
      ),
    );

    final declarativeRouter = router.topMostRouter();
    expect(find.text(SecondNested1Route.name), findsOneWidget);
    expect(declarativeRouter.pageCount, 1);
    pageNotifier.value = 2;
    await tester.pumpAndSettle();
    expect(find.text(SecondNested2Route.name), findsOneWidget);
    expect(declarativeRouter.pageCount, 2);
    pageNotifier.value = 3;
    await tester.pumpAndSettle();
    expect(find.text(SecondNested3Route.name), findsOneWidget);
    expect(declarativeRouter.pageCount, 3);
    pageNotifier.value = 1;
    await tester.pumpAndSettle();
    expect(find.text(SecondNested1Route.name), findsOneWidget);
    expect(declarativeRouter.pageCount, 1);
  });
}
