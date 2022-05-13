import 'package:flutter_test/flutter_test.dart';

import '../router_test_utils.dart';
import 'router.dart';

void main() {
  late AppRouter router;
  setUp(() {
    router = AppRouter();
  });

  testWidgets('Initial route should be ${FirstRoute.name}',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    expect(find.text(FirstRoute.name), findsOneWidget);
  });

  testWidgets('Pushing ${SecondRoute.name} should show [SecondPage]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    expect(find.text(SecondRoute.name), findsOneWidget);
    expect(router.urlState.url,const SecondRoute().path);
  });

  testWidgets('Navigating to ${SecondRoute.name} should show [SecondPage]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(const SecondRoute());
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.urlState.url,const SecondRoute().path);
  });

  testWidgets(
      'Pushing ${SecondRoute.name} then popping should show [FirstPage]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.urlState.url,const FirstRoute().path);
  });

  testWidgets(
      'Pushing ${SecondRoute.name} and ${ThirdRoute.name} should show [ThirdPage]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.pushAll([
      const SecondRoute(),
      const ThirdRoute(),
    ]);
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.urlState.url,const ThirdRoute().path);
  });
}
