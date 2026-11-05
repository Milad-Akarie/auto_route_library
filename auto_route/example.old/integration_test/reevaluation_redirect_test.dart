import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A page reevaluated while its guard redirects is kept, with its state.
// https://github.com/Milad-Akarie/auto_route_library/pull/2343
// Headless test:
// auto_route/test/reevaluatable_router/reevaluation_listener_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ValueNotifier<bool> reevaluationNotifier;
  setUp(() => reevaluationNotifier = ValueNotifier(false));

  // Steps: tap the guarded initial page's counter to 1, fire
  // reevaluateListenable so its guard calls redirectUntil(SecondRoute), then
  // fire it again so the guard lets the page through.
  // Should: the stack is [FirstRoute, SecondRoute], then [FirstRoute] with the
  // counter still at 1.
  testWidgets(
    'Reevaluation with redirectUntil keeps the state of the reevaluated page '
    '(#2343)',
    (tester) async {
      final isLoggedIn = ValueNotifier(true);
      final router = RootStackRouter.build(
        routes: [
          AutoRoute.guarded(
            initial: true,
            page: PageInfo(
              FirstRoute.name,
              builder: (_) => const _CounterPage(),
            ),
            onNavigation: (resolver, router) {
              if (isLoggedIn.value) {
                resolver.next();
              } else {
                unawaited(resolver.redirectUntil(const SecondRoute()));
              }
            },
          ),
          AutoRoute(page: SecondRoute.page),
        ],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: isLoggedIn);
      await tester.tap(find.text('${FirstRoute.name} 0'));
      await tester.pumpAndSettle();
      isLoggedIn.value = false;
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
      ]);
      isLoggedIn.value = true;
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [FirstRoute.name]);
      expect(find.text('${FirstRoute.name} 1'), findsOneWidget);
    },
  );

  // Steps: push the guarded SecondRoute, fire reevaluateListenable so
  // its guard calls redirectUntil(ThirdRoute), then pop ThirdRoute.
  // Should: the stack is [FirstRoute, SecondRoute, ThirdRoute], and popping
  // ThirdRoute without passing the guard also removes SecondRoute.
  testWidgets(
    'Reevaluation with redirectUntil removes the reevaluated page when '
    'rejected (#2343)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, initial: true),
          AutoRoute.guarded(
            page: SecondRoute.page,
            onNavigation: (resolver, router) {
              if (reevaluationNotifier.value) {
                unawaited(resolver.redirectUntil(const ThirdRoute()));
              } else {
                resolver.next();
              }
            },
          ),
          AutoRoute(page: ThirdRoute.page),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        reevaluationNotifier: reevaluationNotifier,
      );
      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      reevaluationNotifier.value = true;
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
        ThirdRoute.name,
      ]);
      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expectTopPage(router, FirstRoute.name);
    },
  );
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: TextButton(
          onPressed: () => setState(() => counter++),
          child: Text('${context.routeData.name} $counter'),
        ),
      ),
    );
  }
}
