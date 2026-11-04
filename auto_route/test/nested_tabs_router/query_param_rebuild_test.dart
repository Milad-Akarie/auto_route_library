import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
    return Text('param ${widget.param}');
  }
}

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2186
  // Steps: MainRoute hosts a nested router with NestedRoutingRoute, which
  // shows AutoTabsRouter.tabBar with PageThatRequiresQueryParamRoute, a page
  // with a @QueryParam. navigatePath('/nested1/nested2?param=true'), then
  // rebuild the widget above MaterialApp, then hot reload.
  // Reported: the page rebuilds on each hot reload, and should not rebuild
  // when a parent calls setState.
  // Should: a parent's setState doesn't build the page again, and neither
  // that nor a hot reload creates a new page state. A hot reload builds every
  // widget again, which is how Flutter's hot reload works.
  testWidgets('A query param page in nested tabs keeps its state when a parent rebuilds', (tester) async {
    _ParamPageState.created = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: 'nested1',
              page: PageInfo(
                'NestedRoutingRoute',
                builder: (_) => const AutoTabsRouter.tabBar(routes: [NamedRoute('PageThatRequiresQueryParamRoute')]),
              ),
              children: [
                AutoRoute(
                  path: 'nested2',
                  initial: true,
                  page: PageInfo(
                    'PageThatRequiresQueryParamRoute',
                    builder: (data) => _ParamPage(param: data.queryParams.getBool('param', false)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    late StateSetter setParentState;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setParentState = setState;
          return MaterialApp.router(routerConfig: router.config());
        },
      ),
    );
    await tester.pumpAndSettle();
    router.navigatePath('/nested1/nested2?param=true');
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
