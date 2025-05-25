@GenerateNiceMocks([MockSpec<AutoRouterObserver>()])
import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'route_observer_test.mocks.dart';
import 'router.dart';

void main() {
  late SimpleRouter router;

  setUp(() {
    router = SimpleRouter();
  });

  testWidgets('Simple observer test', (WidgetTester tester) async {
    final mockObserver = MockAutoRouterObserver();
    await pumpRouterConfigApp(tester, router.config(navigatorObservers: () => [mockObserver]));
    expect(verify(mockObserver.didPush(captureAny, any)).captured.single.settings.name, FirstRoute.name);

    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    expect(verify(mockObserver.didPush(captureAny, any)).captured.single.settings.name, SecondRoute.name);

    router.maybePop();
    await tester.pumpAndSettle();
    expect(verify(mockObserver.didPop(captureAny, any)).captured.single.settings.name, SecondRoute.name);

    router.replace(const SecondRoute());
    await tester.pumpAndSettle();
    expect(verify(mockObserver.didRemove(captureAny, any)).captured.single.settings.name, FirstRoute.name);
    expect(verify(mockObserver.didPush(captureAny, any)).captured.single.settings.name, SecondRoute.name);
  });
}
