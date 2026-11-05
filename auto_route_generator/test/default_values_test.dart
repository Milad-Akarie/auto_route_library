import 'package:test/test.dart';

import 'support/generate.dart';

String _page(String name, {required String parameters, required String fields, String imports = ''}) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
$imports

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key, $parameters});

$fields

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

String _flat(String source) => source.replaceAll(RegExp(r'_i\d+\.'), '').replaceAll(RegExp(r'\s+'), '');

void main() {
  // #404, #443, #444, #456 and #569 (v1 era): a default value that needs an
  // import, or any default of a non-nullable type, was left out or written
  // without its import, so the generated router did not compile ("Getter not
  // found", "Method not found: 'Key'"). The steps: a page whose constructor
  // has the default, then build the router.
  group('a default value in the generated route', () {
    test('an enum from another library keeps its import (#443, #456)', () async {
      final result = await generateRouter({
        'lib/types.dart': 'enum SearchType { shopping, other }',
        'lib/search_page.dart': _page(
          'SearchPage',
          imports: "import 'types.dart';",
          parameters: 'this.searchType = SearchType.shopping',
          fields: '  final SearchType searchType;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, matches(RegExp(r'searchType = _i\d+\.SearchType\.shopping')));
    });

    test('a Key and a Color from the framework compile (#444, #456)', () async {
      final result = await generateRouter({
        'lib/viewer_page.dart': _page(
          'ViewerPage',
          parameters: "Key? inner = const Key(''), this.backgroundColor = const Color(0xFF000000)",
          fields: '  final Color backgroundColor;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });

    test('a non-nullable int and a callback default are kept (#404, #569)', () async {
      final result = await generateRouter({
        'lib/defaults.dart': '''
void defaultLoginHandler(bool ok) {}
''',
        'lib/login_page.dart': _page(
          'LoginPage',
          imports: "import 'defaults.dart';",
          parameters: 'this.onLogin = defaultLoginHandler, this.initialIndex = 2',
          fields: '''
  final void Function(bool) onLogin;
  final int initialIndex;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result.source!);
      expect(source, contains('onLogin=defaultLoginHandler'));
      expect(source, contains('initialIndex=2'));
    });
  });
}
