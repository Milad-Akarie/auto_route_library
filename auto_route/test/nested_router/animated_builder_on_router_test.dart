import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import '../url_title.dart';

void main() {
  // https://github.com/flutter/flutter/issues/110687
  // Reported for go_router: an AnimatedBuilder listening to the router, in a
  // scaffold around the pages, threw "setState() or markNeedsBuild() called
  // during build" on every navigation, and its text did not always update.
  // Steps: a shell page whose AppBar title is
  // AnimatedBuilder(animation: router) showing the url, with the pages in
  // its nested AutoRouter; go from page 1 to page 2 and back, once listening
  // to the root router and once to the nested one.
  // Should: no error, and the title shows each new url.
  for (final listensToRoot in [true, false]) {
    testWidgets(
      'An AnimatedBuilder on the ${listensToRoot ? 'root' : 'nested'} router '
      'follows navigation without errors',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'ShellRoute',
              path: '/',
              builder: (context, _) {
                final listened = listensToRoot ? context.router : null;
                return Scaffold(
                  appBar: AppBar(
                    title: listened == null
                        ? Builder(
                            builder: (context) {
                              final nested = context.innerRouterOf<StackRouter>(
                                'ShellRoute',
                              );
                              return nested == null
                                  ? const SizedBox()
                                  : UrlTitle(nested);
                            },
                          )
                        : UrlTitle(listened),
                  ),
                  body: const AutoRouter(),
                );
              },
              children: [
                NamedRouteDef(
                  name: 'Page1Route',
                  path: '',
                  builder: (context, _) => TextButton(
                    onPressed: () => context.router.navigate<Object?>(
                      const NamedRoute('Page2Route'),
                    ),
                    child: const Text('Go to page 2'),
                  ),
                ),
                NamedRouteDef(
                  name: 'Page2Route',
                  path: 'page2',
                  builder: (context, _) => TextButton(
                    onPressed: () => context.router.navigate<Object?>(
                      const NamedRoute('Page1Route'),
                    ),
                    child: const Text('Go to home page'),
                  ),
                ),
              ],
            ),
          ],
        );
        await pumpRouterConfigApp(tester, router.config());
        final titles = <String>[];
        final errors = <Object?>[];
        void readTitle() {
          errors.add(tester.takeException());
          titles.add(tester.widget<Text>(find.byKey(const Key('title'))).data!);
        }

        readTitle();
        await tester.tap(find.text('Go to page 2'));
        await tester.pumpAndSettle();
        readTitle();
        await tester.tap(find.text('Go to home page'));
        await tester.pumpAndSettle();
        readTitle();
        expect(errors, [null, null, null]);
        expect(titles.join(' | '), '/ | /page2 | /');
      },
    );
  }
}
