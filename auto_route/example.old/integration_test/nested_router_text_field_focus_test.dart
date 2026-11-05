import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/autocomplete_state_field.dart';
import 'support/browser_focus.dart'
    if (dart.library.js_interop) 'support/browser_focus_web.dart';

// A text field in a nested router keeps focus while its Autocomplete options
// open and close, with semantics on.
// Reproduces https://github.com/flutter/flutter/issues/194873 in auto_route.
// Headless test: auto_route/test/nested_router_semantics_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('nested router text field focus', () {
    // Steps: with semantics on, open a page beside a semantics container
    // that shows an AutoRouter, which shows another AutoRouter, which shows
    // an Autocomplete field. Tap the field (its options open), type a letter
    // no option holds (they close), then delete it (they open again).
    // Should: the field keeps its semantics parents, so on the web the
    // browser's focus stays on the field's <input>.
    testWidgets('a nested text field keeps focus', (tester) async {
      final semantics = tester.ensureSemantics();
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'OuterShellRoute',
              builder: (_) => Scaffold(
                body: Row(
                  children: [
                    Semantics(
                      container: true,
                      label: 'Shell navigation',
                      child: const SizedBox(width: 80, child: Text('Nav')),
                    ),
                    const Expanded(child: AutoRouter()),
                  ],
                ),
              ),
            ),
            children: [
              AutoRoute(
                path: '',
                page: PageInfo(
                  'InnerShellRoute',
                  builder: (_) => const AutoRouter(),
                ),
                children: [
                  AutoRoute(
                    path: '',
                    page: PageInfo(
                      'StateFieldRoute',
                      builder: (_) => const AutocompleteStateField(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      List<int> fieldParents() {
        final parents = <int>[];
        for (
          var node = tester.getSemantics(find.byType(EditableText)).parent;
          node != null;
          node = node.parent
        ) {
          parents.add(node.id);
        }
        return parents;
      }

      final unfocused = fieldParents();
      // Off the web there is no DOM, so only the semantics parents count.
      Future<void> expectStillFocused(
        String step, {
        required bool areOptionsShown,
      }) async {
        await tester.pumpAndSettle();
        expect(
          find.text('Texas'),
          areOptionsShown ? findsOneWidget : findsNothing,
        );
        expect(fieldParents(), unfocused, reason: step);
        if (kIsWeb) expect(browserFocusedTag(), 'INPUT', reason: step);
      }

      await tester.tap(find.byType(TextField));
      await expectStillFocused('options opened', areOptionsShown: true);
      await tester.enterText(find.byType(TextField), 'q');
      await expectStillFocused('options closed', areOptionsShown: false);
      await tester.enterText(find.byType(TextField), '');
      await expectStillFocused('options opened again', areOptionsShown: true);
      semantics.dispose();
    });
  });
}
