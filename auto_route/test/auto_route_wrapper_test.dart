import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'router_test_utils.dart';

void main() {
  late WrapperRouter router;

  setUp(() {
    router = WrapperRouter();
  });

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterApp(
        tester,
        router,
      );

  testWidgets(
    'WrappedRoute should wrap the child widget',
    (WidgetTester tester) async {
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
    },
  );
}

// Router Configuration

class WrapperRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: WrapperRoute.page, initial: true),
      ];
}

class WrapperRoute extends PageRouteInfo<void> {
  const WrapperRoute({List<PageRouteInfo>? children}) : super(WrapperRoute.name, initialChildren: children);

  static const String name = 'WrapperRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => WrappedRoute(child: WrapperPage()),
  );
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
