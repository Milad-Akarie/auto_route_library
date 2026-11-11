import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#111137: an editor page asks 'discard changes?' in a
// dialog. Its button pops the dialog and, in the same frame, takes the page
// out of the router's stack (back, removeLast or a navigation away). The
// page vanished at once, with no animation, and cut the dialog's animation
// short: Flutter's DefaultTransitionDelegate completes, rather than pops, a
// leaving page that has pageless routes above it, even when they are already
// popping. Navigator.pop twice animates both. It should: the page animates
// out while the dialog does.
void main() {
  final leaves = <String, void Function(StackRouter)>{
    'back': (router) => router.back(),
    'removeLast': (router) => router.removeLast(),
    'navigatePath': (router) => unawaited(router.navigatePath('/')),
    'maybePop': (router) => unawaited(router.maybePop()),
  };

  for (final MapEntry(key: name, value: leave) in leaves.entries) {
    // On web, back steps through the browser's history instead.
    final shouldSkip = kIsWeb && name == 'back';
    testWidgets(
      '$name right after popping a dialog animates the page out',
      skip: shouldSkip,
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const Text('HomeRoute'),
              ),
            ),
            AutoRoute(
              path: '/editor',
              page: PageInfo(
                'EditorRoute',
                builder: (_) => _EditorPage(onLeave: leave),
              ),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.pushPath('/editor'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        final editorRoute = ModalRoute.of(tester.element(find.text('Close')))!;

        await tester.tap(find.text('Discard'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(editorRoute.animation!.status, AnimationStatus.reverse);
        expect(editorRoute.animation!.value, inExclusiveRange(0, 1));
        expect(find.text('Close'), findsOneWidget);
        expect(find.text('Discard'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(router.stack.map((page) => page.name), ['HomeRoute']);
        expect(find.text('Close'), findsNothing);
        expect(find.text('Discard'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _EditorPage extends StatelessWidget {
  const new({required this.onLeave});

  final void Function(StackRouter) onLeave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          final router = context.router;
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              content: TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onLeave(router);
                },
                child: const Text('Discard'),
              ),
            ),
          );
        },
        child: const Text('Close'),
      ),
    );
  }
}
