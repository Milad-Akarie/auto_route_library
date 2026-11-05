import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late _WrapperRouter router;

  setUp(() {
    router = _WrapperRouter();
  });

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterApp(tester, router);

  testWidgets('WrappedRoute should wrap the child widget', (tester) async {
    await pumpRouter(tester);
    expect(find.byType(_WrapperPage), findsOneWidget);
    expect(find.text('Wrapped'), findsOneWidget);

    // Verify the wrapper widget is present in the tree above the page content
    final textFinder = find.text('Page Content');
    final wrapperFinder = find.text('Wrapped');

    expect(textFinder, findsOneWidget);
    expect(wrapperFinder, findsOneWidget);

    expect(find.text('Wrapped'), findsOneWidget, reason: 'after final wrapperFinder = find.text(Wrapped)');
    expect(find.text('Page Content'), findsOneWidget);

    // Verify structure: Column -> [Text('Wrapped'), Expanded -> _WrapperPage -> Scaffold -> Text('Page Content')]
    final columnFinder = find.byType(Column);
    expect(columnFinder, findsOneWidget);

    expect(find.descendant(of: columnFinder, matching: find.text('Wrapped')), findsOneWidget);
    expect(find.descendant(of: columnFinder, matching: find.text('Page Content')), findsOneWidget);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1713
  // Steps: ParentRoute is an AutoRouter that implements AutoRouteWrapper and
  // provides a state above its nested router, which shows ARoute. A child
  // widget of ARoute, not ARoute itself, calls context.router.push(BRoute()).
  // Reported: wrappedRoute runs again and a new provided state is created.
  // Should: BRoute is pushed in the nested router; the provided state stays.
  // Pushing the absolute path '/parent/b' from the root instead pushes a
  // second ParentRoute with its own wrapper, as the issue's comments explain.
  testWidgets('Pushing a sibling route from a child widget keeps the wrapper of the host route', (tester) async {
    _ProvidedState.created = 0;
    final localRouter = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/parent',
          initial: true,
          page: _ParentRoute.page,
          children: [
            AutoRoute(path: 'a', initial: true, page: _aPage),
            AutoRoute(
              path: 'b',
              page: PageInfo('BRoute', builder: (_) => const Text('BRoute')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, localRouter);
    expect(find.text('Push B'), findsOneWidget);
    expect(_ProvidedState.created, 1);

    await tester.tap(find.text('Push B'));
    await tester.pumpAndSettle();
    expect(localRouter.topRoute.name, 'BRoute');
    expect(localRouter.stack.map((page) => page.name), [_ParentRoute.name]);
    expect(_ProvidedState.created, 1, reason: 'after tester.tap(find.text(Push B))');
  });
}

abstract final class _ParentRoute {
  static const String name = 'ParentRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const _ParentPage());
}

class _ParentPage extends AutoRouter implements AutoRouteWrapper {
  const new();

  @override
  Widget wrappedRoute(BuildContext context) => _Provided(child: this);
}

/// Stands for a BlocProvider: counts the states it creates.
class _Provided extends StatefulWidget {
  const new({required this.child});

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

final PageInfo _aPage = PageInfo('ARoute', builder: (_) => const Scaffold(body: _AChild()));

class _AChild extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => context.router.push(const NamedRoute('BRoute')), child: const Text('Push B'));
  }
}

// Router Configuration

class _WrapperRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: _WrapperRoute.page, initial: true)];
}

abstract final class _WrapperRoute {
  static const String name = 'WrapperRoute';
  static final PageInfo page = PageInfo(name, builder: (data) => const WrappedRoute(child: _WrapperPage()));
}

class _WrapperPage extends StatelessWidget implements AutoRouteWrapper {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Page Content'));
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return Column(
      children: [
        const Text('Wrapped'),
        Expanded(child: this),
      ],
    );
  }
}
