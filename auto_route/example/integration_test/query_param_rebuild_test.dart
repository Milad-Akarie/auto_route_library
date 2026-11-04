import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// A query param page in nested tabs keeps its state when a parent rebuilds.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/2186
// Headless test: auto_route/test/nested_tabs_router/query_param_rebuild_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: MainRoute hosts NestedRoutingRoute, which shows
  // AutoTabsRouter.tabBar with ParamRoute, a page with a query param.
  // navigatePath('/nested1/nested2?param=true'), rebuild the widget above
  // MaterialApp, then reassemble the app as a hot reload does.
  // Should: the parent's rebuild doesn't build the page again, and the page
  // keeps its state through both.
  testWidgets('a query param page in nested tabs keeps its state when a parent rebuilds', (tester) async {
    _ParamPageState.created = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: 'nested1',
              page: PageInfo(
                'NestedRoutingRoute',
                builder: (_) => const AutoTabsRouter.tabBar(routes: [NamedRoute('ParamRoute')]),
              ),
              children: [
                AutoRoute(
                  path: 'nested2',
                  initial: true,
                  page: PageInfo(
                    'ParamRoute',
                    builder: (data) => _ParamPage(param: data.queryParams.getBool('param', false)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final config = router.config(deepLinkBuilder: (link) => link.initial ? const DeepLink.path('/') : link);
    late StateSetter setParentState;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setParentState = setState;
          return MaterialApp.router(routerConfig: config);
        },
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.navigatePath('/nested1/nested2?param=true'));
    await tester.pumpAndSettle();
    expect(find.text('param true'), findsOneWidget);
    expect(_ParamPageState.created, 1);

    _ParamPageState.builds = 0;
    setParentState(() {});
    await tester.pumpAndSettle();
    expect(_ParamPageState.builds, 0);

    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();
    expect(find.text('param true'), findsOneWidget);
    expect(_ParamPageState.created, 1);
  });
}

class _ParamPage extends StatefulWidget {
  const _ParamPage({required this.param});

  final bool param;

  @override
  State<_ParamPage> createState() => _ParamPageState();
}

class _ParamPageState extends State<_ParamPage> {
  static int created = 0;
  static int builds = 0;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    return Scaffold(body: SafeArea(child: Text('param ${widget.param}')));
  }
}
