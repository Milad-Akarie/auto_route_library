import 'package:test/test.dart';

import 'support/generate.dart';

const _kHomePage = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

/// A router library whose `@AutoRouterConfig` sets `replaceInRouteName` to
/// [replaceInRouteName].
String _router(String replaceInRouteName) =>
    '''
import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: '$replaceInRouteName')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [];
}
''';

void main() {
  // Issue #994 was a replaceInRouteName of 'Page, Route', with a space after
  // the comma, that named the route Home Route, so the build failed with a message that it
  // could not format because the source could not be parsed. A value without
  // exactly one comma was ignored without a word, so every route kept its
  // Route suffix.
  group('replaceInRouteName (#994)', () {
    test('ignores spaces around its comma', () async {
      final result = await generateRouter({
        'lib/home_page.dart': _kHomePage,
        'lib/router.dart': _router('Page, Route'),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('class HomeRoute '));
    });

    test('without exactly one comma fails the build naming the option', () async {
      final result = await generateRouter({
        'lib/home_page.dart': _kHomePage,
        'lib/router.dart': _router('Page,Route,X'),
      });
      expect(result.errors.join(), contains('replaceInRouteName must be a pattern and its replacement'));
      expect(result.errors.join(), contains("'Page,Route,X'"));
    });

    test('with a replacement a name cannot hold fails the build naming the option', () async {
      final result = await generateRouter({
        'lib/home_page.dart': _kHomePage,
        'lib/router.dart': _router('Page,Ro ute'),
      });
      expect(result.errors.join(), contains('The replacement in replaceInRouteName'));
      expect(result.errors.join(), contains("'Ro ute'"));
    });
  });

  // #1163: a page parameter named with a `$`, such as `venue$id`, gave a
  // router that didn't compile: the args' toString wrote
  // 'venue$id: $venue$id', which Dart reads as interpolations of `id` and
  // `venue`. A path or query parameter, or a page class, named with a `$`
  // broke the same way in the url keys and the route name.
  test(r'names with a $ compile and stand for themselves (#1163)', () async {
    final result = await generateRouter({
      'lib/venue_page.dart': r'''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class Venue$Page extends StatelessWidget {
  const Venue$Page({
    super.key,
    this.venue$id,
    @PathParam() required this.user$id,
    @QueryParam() this.tab$name,
  });

  final String? venue$id;
  final String user$id;
  final String? tab$name;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains(r"static const String name = 'Venue\$Route';"));
    expect(result.source, contains(r"'Venue\$RouteArgs{key: $key, venue\$id: ${venue$id}, user\$id: ${user$id}"));
    expect(result.source, contains(r"rawPathParams: {'user\$id': user$id}"));
    expect(result.source, contains(r"rawQueryParams: {'tab\$name': tab$name}"));
    expect(result.source, contains(r"pathParams.getString('user\$id')"));
    expect(result.source, contains(r"queryParams.optString('tab\$name')"));
  });
}
