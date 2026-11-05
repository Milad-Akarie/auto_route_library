import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2125
  // A page holds an `id` in its state and builds
  // AutoRouter.declarative(routes: (_) => [HomeRoute(id: id)]).
  // Changing `id` should rebuild the home page with the new id.
  testWidgets(
    'changing a variable of the declarative routes rebuilds the page with it',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _HostRoute.page,
            initial: true,
            children: [AutoRoute(page: _HomeRoute.page, initial: true)],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('Home 1'), findsOneWidget);
      final homeState = tester.state(find.byType(_HomePage));

      await tester.tap(find.text('Next id'));
      await tester.pumpAndSettle();
      expect(find.text('Home 1'), findsNothing);
      expect(find.text('Home 2'), findsOneWidget);
      // The page is updated in place, not replaced by a new one.
      expect(tester.state(find.byType(_HomePage)), same(homeState));
      expect(
        router
            .innerRouterOf<StackRouter>(_HostRoute.name)!
            .current
            .argsAs<_HomeRouteArgs>()
            .id,
        2,
      );
    },
  );
}

abstract final class _HostRoute {
  static const name = 'HostRoute';
  static final page = PageInfo(name, builder: (_) => const _HostPage());
}

class _HostPage extends StatefulWidget {
  const new();

  @override
  State<_HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<_HostPage> {
  int id = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() => id++),
          child: const Text('Next id'),
        ),
        Expanded(
          child: AutoRouter.declarative(routes: (_) => [_HomeRoute(id: id)]),
        ),
      ],
    );
  }
}

@immutable
class _HomeRouteArgs {
  const new({required this.id});

  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _HomeRouteArgs && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class _HomeRoute extends PageRouteInfo<_HomeRouteArgs> {
  new({required int id}) : super(name, args: _HomeRouteArgs(id: id));

  static const name = 'HomeRoute';
  static final page = PageInfo(
    name,
    builder: (data) => _HomePage(id: data.argsAs<_HomeRouteArgs>().id),
  );
}

class _HomePage extends StatefulWidget {
  const new({required this.id});

  final int id;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  Widget build(BuildContext context) => Text('Home ${widget.id}');
}
