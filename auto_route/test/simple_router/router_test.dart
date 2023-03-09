import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../main_router.dart';
import 'router.dart';

class MockListener extends Mock {
  void call();
}

void main() {
  late SimpleRouter _router;
  setUp(() {
    _router = SimpleRouter()..ignorePopCompleters = true;
  });

  void expectHierarchy(List<HierarchySegment> list) {
    expect(_router.currentHierarchy(), list);
  }

  test('Pushing single route should add it to stack and notify navigation history', () async {
    final listener = MockListener();
    _router.navigationHistory.addListener(listener);
    await _router.push(const FirstRoute());
    expectHierarchy(const [HierarchySegment(FirstRoute.name)]);
    verify(listener()).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('Checking if pushed route is active should return true', () async {
    await _router.push(const FirstRoute());
    expect(_router.isPathActive('/'), true);
    expect(_router.isRouteActive(FirstRoute.name), true);
  });

  test('Replacing single route should replace top stack entry and notify navigation history', () async {
    final listener = MockListener();
    _router.navigationHistory.addListener(listener);
    await _router.push(const FirstRoute());
    await _router.replace(const SecondRoute());
    expectHierarchy(const [HierarchySegment(SecondRoute.name)]);
    verify(listener()).called(2);
  });
}
