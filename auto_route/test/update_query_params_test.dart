import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    _SearchPageState.states.clear();
    _SearchPageState.builds = 0;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(page: _SearchRoute.page, path: '/search'),
      ],
    );
  });

  // flutter/flutter#107279: go_router has no way to change the query of the
  // page on screen, as a search field writing '?q=' does, without building
  // the page again. In auto_route, navigate to the route on top with new
  // query params is that way.
  // Steps: open '/search?q=a', count once, then navigate to the same route
  // with q 'b', then 'c'.
  // Should: the url ends in '?q=c', the page shows 'c', its State is the same
  // one (the count is kept), the stack holds one search page, and building
  // stops.
  testWidgets('navigate to the route on top with a new query keeps the page and its state', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/search?q=a');
    expect(find.text('q a, count 0'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('q a, count 1'), findsOneWidget);

    for (final q in ['b', 'c']) {
      unawaited(router.navigate(_SearchRoute(q: q)));
      await tester.pumpAndSettle();
    }
    expect(router.urlState.url, '/search?q=c');
    expect(find.text('q c, count 1'), findsOneWidget);
    expect(_SearchPageState.states, hasLength(1));
    expect(router.stack.map((p) => p.name), [FirstRoute.name, _SearchRoute.pageName]);

    final builds = _SearchPageState.builds;
    await tester.pump(const Duration(seconds: 1));
    expect(_SearchPageState.builds, builds);
  });

  // flutter/flutter#107279, the same from a url: navigatePath to the path on
  // top with a new query keeps the page and its state.
  testWidgets('navigatePath to the url on top with a new query keeps the page and its state', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/search?q=a');
    await tester.tap(find.byType(TextButton));
    await tester.pump();

    unawaited(router.navigatePath('/search?q=b'));
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/search?q=b');
    expect(find.text('q b, count 1'), findsOneWidget);
    expect(_SearchPageState.states, hasLength(1));
  });
}

class _SearchRoute extends PageRouteInfo<void> {
  _SearchRoute({String? q}) : super(pageName, rawQueryParams: {'q': q});

  static const String pageName = 'SearchRoute';
  static PageInfo page = PageInfo(pageName, builder: (data) => _SearchPage(q: data.queryParams.optString('q')));
}

class _SearchPage extends StatefulWidget {
  const _SearchPage({required this.q});

  final String? q;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  static final states = <_SearchPageState>{};
  static int builds = 0;
  var _count = 0;

  @override
  void initState() {
    super.initState();
    states.add(this);
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    return Column(
      children: [
        Text('q ${widget.q}, count $_count'),
        TextButton(onPressed: () => setState(() => _count++), child: const Text('count')),
      ],
    );
  }
}
