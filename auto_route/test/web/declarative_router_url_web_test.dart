@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/763
// Setup: a root page at '/' holds AutoRouter.declarative. Its list page is at
// '' and its details page at 'book/:id'; the details page shows when the
// holder's own state has an id. The routes callback reads the routes a refresh
// opens from its handler, as the README says.
// Steps: open the app at '/book/1', as a refresh does, then move the mouse over
// the page.
// Reported (2.4.2): the address bar changed to '/' on hover after a refresh.
// Should: the page shows book 1 and the address bar stays '/book/1'.
// The address bar is checked here in Chrome's headless runner with the real
// history; what a real browser's hover does is left to the maintainer's
// `flutter drive` run.
void main() {
  useRealBrowserHistory();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearDefaultRouteNameTestValue(),
  );

  late int navigateCalls;
  late RootStackRouter router;
  setUp(() async {
    navigateCalls = 0;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'BooksHostRoute',
            builder: (_) => _BooksHost(onNavigate: () => navigateCalls++),
          ),
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _page('BooksListRoute'), path: ''),
            AutoRoute(page: _page('BookDetailsRoute'), path: 'book/:id'),
          ],
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  testWidgets(
    'On web, a refresh at a book keeps its address while the mouse moves',
    (tester) async {
      openBrowserAt(tester, '/book/1');
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      expect(find.text('BookDetailsRoute 1'), findsOneWidget);
      expect(browserPath, '/book/1');

      final mouse = await tester.createGesture(kind: .mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: .zero);
      await mouse.moveTo(tester.getCenter(find.byType(Scaffold).last));
      await tester.pump(const Duration(milliseconds: 100));
      await settleBrowser(tester);
      expect(browserPath, '/book/1');
      expect(router.currentUrl, '/book/1');
    },
  );
}

PageInfo _page(String name) => .new(
  name,
  builder: (data) => Scaffold(
    body: Text(
      data.params.optString('id') == null
          ? name
          : '$name ${data.params.getString('id')}',
    ),
  ),
);

class _BooksHost extends StatefulWidget {
  const new({required this.onNavigate});

  final VoidCallback onNavigate;

  @override
  State<_BooksHost> createState() => _BooksHostState();
}

class _BooksHostState extends State<_BooksHost> {
  String? _id;

  @override
  Widget build(BuildContext context) => AutoRouter.declarative(
    onPopRoute: (route, page) {
      if (route.name == 'BookDetailsRoute') setState(() => _id = null);
    },
    onNavigate: (matches) {
      widget.onNavigate();
      final last = matches.lastOrNull;
      if (last == null) return;
      final id = last.name == 'BookDetailsRoute'
          ? last.params.optString('id')
          : null;
      if (id == _id) return;
      // As the report's code does: rebuild with the id after the frame, as
      // onNavigate can run while the widget builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _id = id);
      });
    },
    routes: (handler) {
      // The way the README reads the routes a refresh opens the page with.
      final pending = handler.initialPendingRoutes;
      if (pending != null) {
        final details = pending.where((r) => r.routeName == 'BookDetailsRoute');
        _id = details.firstOrNull?.rawPathParams['id'] as String?;
      }
      return [
        const PageRouteInfo('BooksListRoute'),
        if (_id != null)
          PageRouteInfo('BookDetailsRoute', rawPathParams: {'id': _id}),
      ];
    },
  );
}
