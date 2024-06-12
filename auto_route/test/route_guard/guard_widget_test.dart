import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'guard.dart';
import 'router.dart';

void main() {
  late GuardTestRouter router;
  late RedirectOrNextGuard firstRouteGuard;
  late RedirectOrNextGuard secondRouteGuard;
  late _Listenable reevaluate;

  setUp(() {
    firstRouteGuard = RedirectOrNextGuard();
    secondRouteGuard = RedirectOrNextGuard();
    reevaluate = _Listenable();
    router = GuardTestRouter(
      firstRouteGuard: firstRouteGuard,
      secondRouteGuard: secondRouteGuard,
    )..ignorePopCompleters = true;
  });

  tearDown(() {
    reevaluate.dispose();
  });

  testWidgets(
      'Router should redirect to second route after setting redirect in guard',
      (WidgetTester tester) async {
    firstRouteGuard.setRedirect(const SecondRoute());
    await pumpRouterApp(tester, router, reevaluateListenable: reevaluate);
    await tester.pumpAndSettle();
    expect(find.text(SecondRoute.name), findsOneWidget);
    expect(router.urlState.url, '/second-route');
  });

  testWidgets(
      'Router should redirect to second route after setting redirect target in guard '
      'and telling router to reevaluate', (WidgetTester tester) async {
    await pumpRouterApp(tester, router, reevaluateListenable: reevaluate);

    firstRouteGuard.setRedirect(const SecondRoute());
    reevaluate.notify();

    await tester.pumpAndSettle();
    expect(find.text(SecondRoute.name), findsOneWidget);
    expect(router.urlState.url, '/second-route');
  });

  testWidgets(
      'Router should redirect to first route after redirecting to second route from first route and '
      'updating redirect target in guard and telling router to reevaluate',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router, reevaluateListenable: reevaluate);

    firstRouteGuard.setRedirect(const SecondRoute());
    reevaluate.notify();

    await tester.pumpAndSettle();
    expect(find.text(SecondRoute.name), findsOneWidget);
    expect(router.urlState.url, '/second-route');

    secondRouteGuard.setRedirect(const FirstRoute());
    firstRouteGuard.setRedirect(null);
    reevaluate.notify();

    await tester.pumpAndSettle();
    expect(find.text(FirstRoute.name), findsOneWidget);
    expect(router.urlState.url, '/');
  });
}

class _Listenable extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
