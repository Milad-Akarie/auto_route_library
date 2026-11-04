import 'package:test/test.dart';

import 'support/generate.dart';

/// A page library named [name] whose constructor takes [parameters], each
/// also declared as a field in [fields].
String _page(String name, {required String parameters, String fields = ''}) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key, $parameters});

$fields

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

String _squash(String source) => source.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r',(?=[)}\]])'), '');

// Each group guards a bug that go_router_builder had, for the same scenario
// in auto_route's generator.
void main() {
  // flutter/flutter#142397: the same route data class under two parents made
  // go_router_builder write its extension twice, so the file did not build.
  // Steps: list one page in two parents of the router.
  // Should: the router builds and both places are in it.
  group('one page under two parents (flutter/flutter#142397)', () {
    test('compiles', () async {
      final result = await generateRouter({
        'lib/details_page.dart': _page('DetailsPage', parameters: ''),
        'lib/shell_page.dart': _page('ShellAPage', parameters: '').replaceAll('DetailsPage', 'ShellAPage'),
        'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';

import 'details_page.dart';
import 'shell_page.dart';
import 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: ShellARoute.page, path: '/a', children: [AutoRoute(page: DetailsRoute.page, path: 'details')]),
    AutoRoute(page: ShellARoute.page, path: '/b', children: [AutoRoute(page: DetailsRoute.page, path: 'details')]),
  ];
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect('class DetailsRoute extends'.allMatches(result.source!), hasLength(1));
    });
  });

  // flutter/flutter#149675: a list query param that isn't nullable generated
  // `?.map(int.parse).toList()`, which doesn't compile.
  // Should: a list with a default compiles and an absent key gives the
  // default; one without a default is refused with a clear error.
  group('a List query param that is not nullable (flutter/flutter#149675)', () {
    test('with a default compiles and falls back to it', () async {
      final result = await generateRouter({
        'lib/list_page.dart': _page(
          'ListPage',
          parameters: '@QueryParam() this.ids = const []',
          fields: '  final List<int> ids;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(
        _squash(result.source!),
        contains("queryParams.optList('ids')?.map(int.tryParse).whereType<int>().toList()??const[]"),
      );
    });

    test('without a default is refused at build time', () async {
      final result = await generateRouter({
        'lib/list_page.dart': _page(
          'ListPage',
          parameters: '@QueryParam() required this.ids',
          fields: '  final List<int> ids;',
        ),
      });
      expect(result.errors.join(), contains('QueryParams must be nullable or have default value'));
    });
  });

  // flutter/flutter#164354: a required enum query param could not be parsed.
  // Should: an enum with a default compiles and reads by name.
  test('an enum query param with a default compiles (flutter/flutter#164354)', () async {
    final result = await generateRouter({
      'lib/mode_page.dart':
          '''
${_page('ModePage', parameters: '@QueryParam() this.mode = Mode.foo', fields: '  final Mode mode;')}

enum Mode { foo, bar }
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(
      _squash(result.source!),
      matches(RegExp(r"Mode\.values\.asNameMap\(\)\[queryParams\.optString\('mode'\)\]\?\?(_i\d+\.)?Mode\.foo")),
    );
  });

  // flutter/flutter#164621: `int.parse(...)!` made the analyzer warn that the
  // `!` has no effect; #170241: the generated mixin warned about overriding.
  // Should: the generated file has no analyzer errors, reads an int path
  // param with getInt, and carries `ignore_for_file: type=lint` for warnings.
  test('an int path param is read with getInt and the file is lint-free (flutter/flutter#164621, #170241)', () async {
    final result = await generateRouter({
      'lib/product_page.dart': _page(
        'ProductPage',
        parameters: '@PathParam() required this.id',
        fields: '  final int id;',
      ),
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains("pathParams.getInt('id')"));
    expect(result.source, contains('ignore_for_file: type=lint'));
    expect(result.source, isNot(contains('!)')));
  });

  // flutter/flutter#161919: a shell route's path param was not passed to the
  // shell's constructor. Should: a page that hosts nested routes and takes
  // @PathParam gets the param in its generated args.
  test('a page hosting nested routes receives its path param (flutter/flutter#161919)', () async {
    final result = await generateRouter({
      'lib/home_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomeShellPage extends StatelessWidget {
  const HomeShellPage({super.key, @PathParam() required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => const AutoRouter();
}

@RoutePage()
class ChildPage extends StatelessWidget {
  const ChildPage({super.key, @PathParam.inherit() required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';

import 'home_page.dart';
import 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeShellRoute.page, path: '/home/:id', children: [AutoRoute(page: ChildRoute.page, path: '')]),
  ];
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    final source = _squash(result.source!);
    expect(source, contains("id:pathParams.getString('id')"));
  });
}
