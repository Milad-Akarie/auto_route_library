import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Pushing a sibling route from a child widget keeps the wrapper of the host
// route.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/1713
// Headless test: auto_route/test/auto_route_wrapper_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: ParentRoute is an AutoRouter that implements AutoRouteWrapper and
  // provides a state above its nested router, which shows ARoute. Tap a
  // button in a child widget of ARoute that calls context.router.push(BRoute).
  // Should: BRoute shows, and the provided state is created only once.
  testWidgets(
    'pushing a sibling route from a child widget keeps the host wrapper',
    (tester) async {
      _ProvidedState.created = 0;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('ParentRoute', builder: (_) => const _ParentPage()),
            children: [
              AutoRoute(
                path: '',
                page: PageInfo(
                  'ARoute',
                  builder: (_) =>
                      const Scaffold(body: SafeArea(child: _AChild())),
                ),
              ),
              AutoRoute(
                path: 'b',
                page: PageInfo(
                  'BRoute',
                  builder: (_) =>
                      const Scaffold(body: SafeArea(child: Text('BRoute'))),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(_ProvidedState.created, 1);

      await tester.tap(find.text('Push B'));
      await tester.pumpAndSettle();
      expectTopPage(router, 'BRoute');
      expect(router.stack.map((page) => page.name), ['ParentRoute']);
      expect(_ProvidedState.created, 1);
    },
  );
}

class _ParentPage extends AutoRouter implements AutoRouteWrapper {
  const _ParentPage();

  @override
  Widget wrappedRoute(BuildContext context) => _Provided(child: this);
}

/// Stands for a BlocProvider: counts the states it creates.
class _Provided extends StatefulWidget {
  const _Provided({required this.child});

  final Widget child;

  @override
  State<_Provided> createState() => _ProvidedState();
}

class _ProvidedState extends State<_Provided> {
  static int created = 0;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AChild extends StatelessWidget {
  const _AChild();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.router.push(const NamedRoute('BRoute')),
      child: const Text('Push B'),
    );
  }
}
