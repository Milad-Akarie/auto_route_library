import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// A nested router built in a different place of its page's widget tree, as an
// app does when it shows a list beside the detail on a wide window and the
// detail alone on a narrow one, such as when a foldable phone is folded.
// Without a global key, Flutter builds a new nested router there. It used to
// open its initial pages, so folding the phone dropped the open detail page
// and the url went back to the list.
void main() {
  late RootStackRouter router;

  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    await tester.pumpAndSettle();
  }

  group('a nested stack router moved in the tree', () {
    late int guardChecks;
    setUp(() {
      guardChecks = 0;
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            path: '/mail',
            page: _mailPage,
            children: [
              AutoRoute(initial: true, path: '', page: _inboxPage),
              AutoRoute(path: ':id', page: _messagePage),
              AutoRoute(
                path: 'drafts/:id',
                page: _draftPage,
                guards: [
                  AutoRouteGuard.simple((resolver, _) {
                    guardChecks++;
                    resolver.next();
                  }),
                ],
              ),
            ],
          ),
        ],
      );
    });

    // Steps: on a wide window, open message 2 beside the list; make the
    // window narrow; go back; open message 1; make the window wide again.
    testWidgets('keeps its pages, its url and going back', (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('Pick a message'), findsOneWidget);

      await tester.tap(find.text('Message 2'));
      await tester.pumpAndSettle();
      expect(find.text('Showing message 2'), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      expect(router.currentPath, '/mail/2');

      await setWidth(tester, 400);
      expect(find.text('Showing message 2'), findsOneWidget);
      expect(find.text('Message 1'), findsNothing);
      expect(router.currentPath, '/mail/2');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Message 1'), findsOneWidget);
      expect(router.currentPath, '/mail');

      await tester.tap(find.text('Message 1'));
      await tester.pumpAndSettle();
      await setWidth(tester, 900);
      expect(find.text('Showing message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
      expect(router.currentPath, '/mail/1');
    });

    // Steps: on a wide window, open a draft, whose route has a guard; make
    // the window narrow.
    testWidgets('keeps a guarded page without checking its guard again', (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await pumpRouterConfigApp(tester, router.config());

      unawaited(router.navigatePath('/mail/drafts/3'));
      await tester.pumpAndSettle();
      expect(find.text('Showing draft 3'), findsOneWidget);
      expect(guardChecks, 1);

      await setWidth(tester, 400);
      expect(find.text('Showing draft 3'), findsOneWidget);
      expect(find.text('Message 1'), findsNothing);
      expect(router.currentPath, '/mail/drafts/3');
      expect(guardChecks, 1);
    });
  });

  // This already worked; it guards the tabs router against the change above.
  group('a nested tabs router moved in the tree', () {
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            path: '/home',
            page: _homePage,
            children: [
              AutoRoute(initial: true, path: 'feed', page: _tabPage('Feed')),
              AutoRoute(path: 'profile', page: _tabPage('Profile')),
            ],
          ),
        ],
      );
    });

    // Steps: on a wide window, open the profile tab; make the window narrow.
    testWidgets('keeps its active tab', (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('Feed tab'), findsOneWidget);

      await tester.tap(find.text('Open profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile tab'), findsOneWidget);
      expect(router.currentPath, '/home/profile');

      await setWidth(tester, 400);
      expect(find.text('Profile tab'), findsOneWidget);
      expect(router.currentPath, '/home/profile');
    });
  });
}

bool _isWide(BuildContext context) => MediaQuery.widthOf(context) >= 600;

final _mailPage = PageInfo('MailRoute', builder: (_) => const _MailPage());
final _inboxPage = PageInfo('InboxRoute', builder: (_) => const _InboxPage());
final _messagePage = PageInfo(
  'MessageRoute',
  builder: (data) => Scaffold(body: Text('Showing message ${data.params.getString('id')}')),
);
final _draftPage = PageInfo(
  'DraftRoute',
  builder: (data) => Scaffold(body: Text('Showing draft ${data.params.getString('id')}')),
);
final _homePage = PageInfo('HomeRoute', builder: (_) => const _HomePage());
PageInfo _tabPage(String name) => .new('${name}Route', builder: (_) => Text('$name tab'));

class _MailPage extends StatelessWidget {
  const _MailPage();

  @override
  Widget build(BuildContext context) {
    if (!_isWide(context)) return const AutoRouter();
    return const Row(
      children: [
        SizedBox(width: 200, child: _MessageList()),
        Expanded(child: AutoRouter()),
      ],
    );
  }
}

class _InboxPage extends StatelessWidget {
  const _InboxPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _isWide(context) ? const Text('Pick a message') : const _MessageList());
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final id in ['1', '2'])
          TextButton(onPressed: () => context.router.navigatePath('/mail/$id'), child: Text('Message $id')),
      ],
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final tabs = AutoTabsRouter(
      builder: (context, child) => Column(
        children: [
          TextButton(onPressed: () => context.tabsRouter.setActiveIndex(1), child: const Text('Open profile')),
          Expanded(child: child),
        ],
      ),
    );
    if (!_isWide(context)) return Scaffold(body: tabs);
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 200),
          Expanded(child: tabs),
        ],
      ),
    );
  }
}
