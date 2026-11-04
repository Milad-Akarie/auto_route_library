import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late WrapperRouter router;

  setUp(() {
    router = WrapperRouter();
  });

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterApp(tester, router);

  testWidgets('WrappedRoute should wrap the child widget', (WidgetTester tester) async {
    await pumpRouter(tester);
    expect(find.byType(WrapperPage), findsOneWidget);
    expect(find.text('Wrapped'), findsOneWidget);

    // Verify the wrapper widget is present in the tree above the page content
    final textFinder = find.text('Page Content');
    final wrapperFinder = find.text('Wrapped');

    expect(textFinder, findsOneWidget);
    expect(wrapperFinder, findsOneWidget);

    expect(find.text('Wrapped'), findsOneWidget);
    expect(find.text('Page Content'), findsOneWidget);

    // Verify structure: Column -> [Text('Wrapped'), Expanded -> WrapperPage -> Scaffold -> Text('Page Content')]
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
  testWidgets('Pushing a sibling route from a child widget keeps the wrapper of the host route', (
    WidgetTester tester,
  ) async {
    _ProvidedState.created = 0;
    final router = RootStackRouter.build(
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
    await pumpRouterApp(tester, router);
    expect(find.text('Push B'), findsOneWidget);
    expect(_ProvidedState.created, 1);

    await tester.tap(find.text('Push B'));
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'BRoute');
    expect(router.stack.map((page) => page.name), [_ParentRoute.name]);
    expect(_ProvidedState.created, 1);
  });
}

class _ParentRoute extends PageRouteInfo<void> {
  const _ParentRoute() : super(name);

  static const String name = 'ParentRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _ParentPage());
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

PageInfo _aPage = PageInfo('ARoute', builder: (_) => const Scaffold(body: _AChild()));

class _AChild extends StatelessWidget {
  const _AChild();

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => context.router.push(const NamedRoute('BRoute')), child: const Text('Push B'));
  }
}

// Router Configuration

class WrapperRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: WrapperRoute.page, initial: true)];
}

class WrapperRoute extends PageRouteInfo<void> {
  const WrapperRoute({List<PageRouteInfo>? children}) : super(WrapperRoute.name, initialChildren: children);

  static const String name = 'WrapperRoute';
  static PageInfo page = PageInfo(name, builder: (data) => WrappedRoute(child: WrapperPage()));
}

class WrapperPage extends StatelessWidget implements AutoRouteWrapper {
  const WrapperPage({super.key});

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
