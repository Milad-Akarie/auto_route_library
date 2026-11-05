import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A nested router keeps its pages when its page builds it in another place,
// as a list-detail page does when a foldable phone folds and the two panes
// become one. It used to open its initial pages again, dropping the detail.
// Headless test: auto_route/test/nested_router/moved_router_keeps_pages_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: on a wide window, open message 2 beside the list. Make the window
  // narrow, then go back.
  // Should: message 2 stays open alone with its url; back shows the list.
  testWidgets('a nested router keeps its pages when the two panes become one', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          initial: true,
          path: '/mail',
          page: PageInfo('MailRoute', builder: (_) => const _MailPage()),
          children: [
            AutoRoute(
              initial: true,
              path: '',
              page: PageInfo('InboxRoute', builder: (_) => const _InboxPage()),
            ),
            AutoRoute(
              path: ':id',
              page: PageInfo(
                'MessageRoute',
                builder: (data) => Scaffold(
                  body: Text('Showing message ${data.params.getString('id')}'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    await pumpRouterApp(tester, router);
    expect(find.text('Pick a message'), findsOneWidget);

    await tester.tap(find.text('Message 2'));
    await tester.pumpAndSettle();
    expect(find.text('Showing message 2'), findsOneWidget);
    expect(find.text('Message 1'), findsOneWidget);
    await expectBrowserUrl('/mail/2');

    tester.view.physicalSize = const Size(400, 700);
    await tester.pumpAndSettle();
    expect(find.text('Showing message 2'), findsOneWidget);
    expect(find.text('Message 1'), findsNothing);
    expect(router.currentPath, '/mail/2');
    await expectBrowserUrl('/mail/2');

    await systemBack(tester);
    expect(find.text('Message 1'), findsOneWidget);
    expect(router.currentPath, '/mail');
    await expectBrowserUrl('/mail');
  });
}

bool _isWide(BuildContext context) => MediaQuery.widthOf(context) >= 600;

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
    return Scaffold(
      body: _isWide(context)
          ? const Text('Pick a message')
          : const _MessageList(),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final id in ['1', '2'])
          TextButton(
            onPressed: () => context.router.navigatePath('/mail/$id'),
            child: Text('Message $id'),
          ),
      ],
    );
  }
}
