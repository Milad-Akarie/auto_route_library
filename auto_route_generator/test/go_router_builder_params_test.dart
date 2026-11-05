import 'package:test/test.dart';

import 'support/generate.dart';

/// A page library named [name] whose constructor takes [parameters], each
/// also declared as a field in [fields]. [constructor] is `const` or empty.
String _page(
  String name, {
  String imports = '',
  required String parameters,
  required String fields,
  String constructor = 'const',
}) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
$imports

@RoutePage()
class $name extends StatelessWidget {
  $constructor $name({super.key, $parameters});

$fields

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

/// The generated source without import prefixes, white space and trailing
/// commas, so a test can look for a line of code.
String _flat(GeneratedRouter result) => result.source!
    .replaceAll(RegExp(r'_i\d+\.'), '')
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp(r',(?=[)}\]])'), '');

void main() {
  // flutter/flutter#105876: go_router_builder wrote an enum param through a
  // map of every field of the enum, so an enhanced enum failed to compile
  // ("Member not found: 'themeColor'"). auto_route reads and writes an enum
  // query param by its name only; the fields don't matter.
  group('an enhanced enum query parameter (flutter/flutter#105876)', () {
    test('is read and written by its name', () async {
      final result = await generateRouter({
        'lib/fruit.dart': '''
import 'dart:ui';

enum Fruit {
  apple(themeColor: Color(0xFFFF0000)),
  banana(themeColor: Color(0xFFFFFF00));

  const Fruit({required this.themeColor});

  final Color themeColor;
}
''',
        'lib/fruit_page.dart': _page(
          'FruitPage',
          imports: "import 'fruit.dart';",
          parameters: '@QueryParam() this.fruit, @QueryParam() this.other = Fruit.banana',
          fields: '''
  final Fruit? fruit;
  final Fruit other;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains("rawQueryParams:{'fruit':fruit?.name,'other':other.name}"));
      expect(source, contains("fruit:Fruit.values.asNameMap()[queryParams.optString('fruit')]"));
    });
  });

  // flutter/flutter#114406: go_router_builder passed a nullable value to a
  // parameter with a default. auto_route hands the default to the getter, so
  // a missing value gives the default.
  group('a query parameter with a default value (flutter/flutter#114406)', () {
    test('reads the default when the url has no value', () async {
      final result = await generateRouter({
        'lib/home_page.dart': _page(
          'HomePage',
          parameters: '@QueryParam() this.first, @QueryParam() this.second = "default", @QueryParam() this.count = 3',
          fields: '''
  final String? first;
  final String second;
  final int count;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains("first:queryParams.optString('first')"));
      expect(source, contains('second:queryParams.getString(\'second\',"default")'));
      expect(source, contains("count:queryParams.getInt('count',3)"));
    });
  });

  // flutter/flutter#116837: a non-nullable enum query param with a default,
  // `HomeTab tab = HomeTab.home`, generated a _fromState that didn't compile.
  group('an enum query parameter with a default (flutter/flutter#116837)', () {
    test('compiles and reads the default when the url has none', () async {
      final result = await generateRouter({
        'lib/tabs.dart': 'enum HomeTab { home, profile, settings }',
        'lib/home_page.dart': _page(
          'HomePage',
          imports: "import 'tabs.dart';",
          parameters: '@QueryParam() this.tab = HomeTab.home',
          fields: '  final HomeTab tab;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains("tab:HomeTab.values.asNameMap()[queryParams.optString('tab')]??HomeTab.home"));
      expect(source, contains("'tab':tab.name"));
    });
  });

  // flutter/flutter#121934 and #131211: go_router_builder wrote `const` before
  // a route data constructor call, which failed to compile when the call took
  // a runtime value (`$extra`) or when the class had no const constructor.
  // auto_route builds the page with its args as `Page(args.x)` and marks the
  // route const only when the page has no parameters and a const constructor.
  group('a page with a parameter (flutter/flutter#121934, #131211)', () {
    test('with a const constructor is built without const', () async {
      final result = await generateRouter({
        'lib/booking_page.dart': _page(
          'BookingPage',
          parameters: '@QueryParam() this.hotel',
          fields: '  final String? hotel;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(_flat(result), contains('returnBookingPage(key:args.key,hotel:args.hotel)'));
      expect(_flat(result), isNot(contains('constBookingPage(')));
    });

    test('without a const constructor compiles', () async {
      final result = await generateRouter({
        'lib/shell_page.dart': _page(
          'ShellPage',
          constructor: '',
          parameters: '@QueryParam() this.title',
          fields: '  final String? title;',
        ),
        'lib/plain_page.dart': _page('PlainPage', constructor: '', parameters: '', fields: ''),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(_flat(result), isNot(contains('constShellPage(')));
      expect(_flat(result), isNot(contains('constPlainPage(')));
    });
  });

  // flutter/flutter#126796: go_router_builder asked for required query
  // params. A url may leave a query param out, so auto_route refuses a
  // non-null query param without a default at build time, by design; a value
  // a page always needs is a @PathParam.
  group('a required query parameter (flutter/flutter#126796)', () {
    test('without a default is a build error', () async {
      final result = await generateRouter({
        'lib/my_page.dart': _page(
          'MyPage',
          parameters: "@QueryParam('my-param') required this.myParam",
          fields: '  final String myParam;',
        ),
      });
      expect(result.errors, hasLength(1));
      expect(result.errors.join(), contains('QueryParams must be nullable or have default value'));
    });

    test('with a path param next to it compiles', () async {
      final result = await generateRouter({
        'lib/my_page.dart': _page(
          'MyPage',
          parameters: "@PathParam('routeId') required this.routeId, @QueryParam('my-param') this.myParam",
          fields: '''
  final String routeId;
  final String? myParam;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });
  });

  // flutter/flutter#122003 and #122181: go_router_builder dropped the default
  // value of an iterable param and wrote no enum map for the items of an
  // iterable of enums. auto_route supports a List of enums with a default,
  // read and written by name. Iterable and Set are not supported (batch gen).
  group('a list query parameter with a default (flutter/flutter#122003, #122181)', () {
    test('of enums keeps the default and the item names', () async {
      final result = await generateRouter({
        'lib/types.dart': 'enum MyEnum { value0, value1 }',
        'lib/my_page.dart': _page(
          'MyPage',
          imports: "import 'types.dart';",
          parameters: '@QueryParam() this.values = const [MyEnum.value0], @QueryParam() this.texts = const ["a"]',
          fields: '''
  final List<MyEnum> values;
  final List<String> texts;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(
        source,
        contains(
          "values:queryParams.optList('values')?.map((name)=>MyEnum.values.asNameMap()[name])"
          '.whereType<MyEnum>().toList()??const[MyEnum.value0]',
        ),
      );
      expect(source, contains("'values':values.map((item)=>item.name).toList()"));
      expect(source, contains('texts:queryParams.getList(\'texts\',const["a"])'));
    });
  });
}
