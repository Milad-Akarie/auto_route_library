import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../main_router.dart';
import '../simple_router/router_test.dart';
import 'guard.dart';
import 'router.dart';

void main() {
  late GuardTestRouter router;
  late RedirectOrNextGuard firstRouteGuard;
  late RedirectOrNextGuard secondRouteGuard;
  setUp(() {
    firstRouteGuard = RedirectOrNextGuard();
    secondRouteGuard = RedirectOrNextGuard();
    router = GuardTestRouter(
      firstRouteGuard: firstRouteGuard,
      secondRouteGuard: secondRouteGuard,
    )..ignorePopCompleters = true;
  });

  test(
      'Pushing first route should not redirect to second route if no redirect is set',
      () async {
    final listener = MockListener();
    router.navigationHistory.addListener(listener.call);

    expect(router.currentHierarchy(), []);

    await router.push(const FirstRoute());

    expect(
      router.currentHierarchy(),
      [const HierarchySegment(FirstRoute.name)],
    );

    verify(listener()).called(1);
    verifyNoMoreInteractions(listener);
  });

  test(
      'Pushing first route after setting redirect in guard should redirect to second route',
      () async {
    final listener = MockListener();
    router.navigationHistory.addListener(listener.call);

    expect(router.currentHierarchy(), []);

    firstRouteGuard.setRedirect(const SecondRoute());

    await router.push(const FirstRoute()).timeout(const Duration(seconds: 1));

    expect(
      router.currentHierarchy(),
      [const HierarchySegment(SecondRoute.name)],
    );

    verify(listener()).called(1);
    verifyNoMoreInteractions(listener);
  });
}
