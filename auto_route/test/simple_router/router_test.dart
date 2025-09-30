import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../main_router.dart';
import 'router.dart';

class MockListener extends Mock {
  void call();
}

class MockOnNavigationFailureListener extends Mock {
  void call(NavigationFailure? failure);
}

void main() {
  late SimpleRouter router;
  setUp(() {
    router = SimpleRouter()..ignorePopCompleters = true;
  });

  void expectHierarchy(List<HierarchySegment> list) {
    expect(router.currentHierarchy(), list);
  }

  test('Pushing single route should add it to stack and notify navigation history', () async {
    final listener = MockListener();
    router.navigationHistory.addListener(listener.call);
    await router.push(const FirstRoute());
    expectHierarchy(const [HierarchySegment(FirstRoute.name)]);
    verify(listener()).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('Checking if pushed route is active should return true', () async {
    await router.push(const FirstRoute());
    expect(router.isPathActive('/'), true);
    expect(router.isRouteActive(FirstRoute.name), true);
  });

  test('Replacing single route should replace top stack entry and notify navigation history', () async {
    final listener = MockListener();
    router.navigationHistory.addListener(listener.call);
    await router.push(const FirstRoute());
    await router.replace(const SecondRoute());
    expectHierarchy(const [HierarchySegment(SecondRoute.name)]);
    verify(listener()).called(2);
  });

  test('Navigating to a none-declared route should call onFailure(<RouteNotFoundFailure>)', () async {
    final mockListener = MockOnNavigationFailureListener();
    await router.push(const SecondNested1Route(), onFailure: mockListener.call);
    expect(verify(mockListener(captureAny)).captured.single, isA<RouteNotFoundFailure>());
  });

  test('Navigating to a none-declared path should call onFailure(<RouteNotFoundFailure>)', () async {
    final mockListener = MockOnNavigationFailureListener();
    await router.navigatePath('/none-declared', onFailure: mockListener.call);
    expect(verify(mockListener(captureAny)).captured.single, isA<RouteNotFoundFailure>());
  });

  test('Routes rejected by guards should call onFailure(<RejectedByGuardFailure>)', () async {
    final mockListener = MockOnNavigationFailureListener();
    await router.push(const FourthRoute(), onFailure: mockListener.call);
    expect(verify(mockListener(captureAny)).captured.single, isA<RejectedByGuardFailure>());
  });
}
