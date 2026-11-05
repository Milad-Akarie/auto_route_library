import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _HomePage extends StatefulWidget {
  const new();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return Scaffold(
      body: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Not registered')),
          ),
        ),
        child: const Text('Open'),
      ),
    );
  }
}

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2211
  // Steps: on HomeRoute, push a page the router doesn't know with
  // Navigator.push(context, MaterialPageRoute(...)), then go back.
  // Reported: the current page builds again as soon as the push starts.
  // Should: the page underneath isn't built again.
  testWidgets(
    'Navigator.push of a page outside the router does not rebuild the page '
    'underneath',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => const _HomePage()),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      _HomePageState homeState() => tester.state<_HomePageState>(
        find.byType(_HomePage, skipOffstage: false),
      );
      homeState().builds = 0;

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Not registered'), findsOneWidget);
      expect(homeState().builds, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(
        homeState().builds,
        0,
        reason: 'after tester.binding.handlePopRoute()',
      );
    },
  );
}
