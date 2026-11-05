import 'package:test/test.dart';

import 'support/generate.dart';

const _kShellPage = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) => const AutoRouter();
}
''';

String _nestedPage({String annotation = '@RoutePage()'}) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

$annotation
class NestedPage extends StatelessWidget {
  const NestedPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

String _router({String annotation = '@AutoRouterConfig()'}) =>
    '''
import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

$annotation
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: ShellRoute.page,
          children: [AutoRoute(path: 'nested', page: NestedRoute.page)],
        ),
      ];
}
''';

/// The import line the generated router has for [file], whatever its prefix.
String? _importOf(String source, String file) => RegExp(
  "^import 'package:app/$file'.*\$",
  multiLine: true,
).firstMatch(source)?.group(0);

void main() {
  // A page that sits only in a nested router's `children` loads on demand
  // like a top-level one. The generator never sees the route tree: it builds
  // a route for each `@RoutePage` class, and whether that route is deferred
  // comes from the page's `@RoutePage(deferredLoading:)` or the router's
  // `@AutoRouterConfig(deferredLoading:)`, not from where `routes` places it.
  group('a page only inside a child route', () {
    test('is deferred by the router default', () async {
      final result = await generateRouter({
        'lib/shell_page.dart': _kShellPage,
        'lib/nested_page.dart': _nestedPage(),
        'lib/router.dart': _router(
          annotation: '@AutoRouterConfig(deferredLoading: true)',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = result.source!;
      expect(_importOf(source, 'nested_page.dart'), contains('deferred as'));
      expect(
        source,
        matches(
          RegExp(
            r'DeferredWidget\(\s*_i\d+\.loadLibrary,\s*\(\) => _i\d+\.NestedPage\(\)',
          ),
        ),
      );
    });

    test('is deferred by its own @RoutePage, and its shell is not', () async {
      final result = await generateRouter({
        'lib/shell_page.dart': _kShellPage,
        'lib/nested_page.dart': _nestedPage(
          annotation: '@RoutePage(deferredLoading: true)',
        ),
        'lib/router.dart': _router(),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = result.source!;
      expect(_importOf(source, 'nested_page.dart'), contains('deferred as'));
      expect(
        source,
        matches(
          RegExp(
            r'DeferredWidget\(\s*_i\d+\.loadLibrary,\s*\(\) => _i\d+\.NestedPage\(\)',
          ),
        ),
      );
      expect(_importOf(source, 'shell_page.dart'), isNot(contains('deferred')));
      expect(source, isNot(matches(RegExp(r'DeferredWidget\([^;]*ShellPage'))));
    });
  });

  // Dart defers a whole library, not one class in it, so when one page of a
  // file loads on demand, every page in that file must. Steps: one file
  // declares two `@RoutePage` classes; one is deferred by its own
  // `@RoutePage(deferredLoading: true)`, or by the router default while the
  // other is left to it or opts out; build the router. Before the fix the
  // file was imported deferred or not by whichever page came first, and the
  // other page's route did not compile: a `const` page from a deferred
  // library, or `loadLibrary` on a plain import.
  group('two pages in one file', () {
    String twoPages({
      String first = '@RoutePage()',
      String second = '@RoutePage()',
    }) =>
        '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

$first
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

$second
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

    String router({String annotation = '@AutoRouterConfig()'}) =>
        '''
import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

$annotation
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/', page: FirstRoute.page),
        AutoRoute(path: '/second', page: SecondRoute.page),
      ];
}
''';

    void expectBothDeferred(GeneratedRouter result) {
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = result.source!;
      expect(_importOf(source, 'pages.dart'), contains('deferred as'));
      for (final page in ['FirstPage', 'SecondPage']) {
        expect(
          source,
          matches(
            RegExp(
              r'DeferredWidget\(\s*_i\d+\.loadLibrary,\s*\(\) => _i\d+\.'
              '$page'
              r'\(\)',
            ),
          ),
        );
      }
    }

    for (final deferred in ['first', 'second']) {
      test(
        'loads both on demand when the $deferred is deferred by its @RoutePage',
        () async {
          const annotation = '@RoutePage(deferredLoading: true)';
          final result = await generateRouter({
            'lib/pages.dart': deferred == 'first'
                ? twoPages(first: annotation)
                : twoPages(second: annotation),
            'lib/router.dart': router(),
          });
          expectBothDeferred(result);
        },
      );
    }

    for (final optedOut in ['first', 'second']) {
      test(
        'loads neither on demand when the $optedOut opts out of the router default',
        () async {
          const annotation = '@RoutePage(deferredLoading: false)';
          final result = await generateRouter({
            'lib/pages.dart': optedOut == 'first'
                ? twoPages(first: annotation)
                : twoPages(second: annotation),
            'lib/router.dart': router(
              annotation: '@AutoRouterConfig(deferredLoading: true)',
            ),
          });
          expect(result.errors, isEmpty);
          expect(result.compileErrors, isEmpty);
          final source = result.source!;
          expect(_importOf(source, 'pages.dart'), isNot(contains('deferred')));
          expect(source, isNot(contains('DeferredWidget')));
        },
      );
    }
  });
}
