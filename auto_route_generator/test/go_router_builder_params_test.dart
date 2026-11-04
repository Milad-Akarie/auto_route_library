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
}
