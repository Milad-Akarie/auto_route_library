import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Changing a variable of a declarative router's routes rebuilds the page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2125
// Headless test: auto_route/test/nested_router/declarative_routes_update_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: a page holds an `id` in its state and builds
  // AutoRouter.declarative(routes: (_) => [HomeRoute(id: id)]). Tap the
  // button that changes `id`.
  // Should: the home page shows the new id, updated in place.
  testWidgets('changing a variable of the declarative routes rebuilds the page with it', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _HostRoute.page,
          initial: true,
          children: [AutoRoute(page: _HomeRoute.page, initial: true)],
        ),
      ],
    );
    await pumpRouterAppWithConfig(tester, router);
    expect(find.text('Home 1'), findsOneWidget);
    final homeState = tester.state(find.byType(_HomePage));

    await tester.tap(find.text('Next id'));
    await tester.pumpAndSettle();
    expect(find.text('Home 1'), findsNothing);
    expect(find.text('Home 2'), findsOneWidget);
    expect(tester.state(find.byType(_HomePage)), same(homeState));
  });
}

class _HostRoute extends PageRouteInfo<void> {
  const _HostRoute() : super(name);

  static const name = 'HostRoute';
  static final page = PageInfo(name, builder: (_) => const _HostPage());
}

class _HostPage extends StatefulWidget {
  const _HostPage();

  @override
  State<_HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<_HostPage> {
  int id = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: () => setState(() => id++), child: const Text('Next id')),
          Expanded(
            child: AutoRouter.declarative(routes: (_) => [_HomeRoute(id: id)]),
          ),
        ],
      ),
    );
  }
}

class _HomeRouteArgs {
  const _HomeRouteArgs({required this.id});

  final int id;

  @override
  bool operator ==(Object other) => identical(this, other) || other is _HomeRouteArgs && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class _HomeRoute extends PageRouteInfo<_HomeRouteArgs> {
  _HomeRoute({required int id}) : super(name, args: _HomeRouteArgs(id: id));

  static const name = 'HomeRoute';
  static final page = PageInfo(name, builder: (data) => _HomePage(id: data.argsAs<_HomeRouteArgs>().id));
}

class _HomePage extends StatefulWidget {
  const _HomePage({required this.id});

  final int id;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  Widget build(BuildContext context) => Text('Home ${widget.id}');
}
