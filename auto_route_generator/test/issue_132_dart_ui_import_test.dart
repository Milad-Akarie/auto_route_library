import 'package:test/test.dart';

import 'support/generate.dart';

String _page(
  String name, {
  required String parameters,
  required String fields,
  String imports = '',
}) =>
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

void main() {
  // #132: "dart:ui" was imported in the generated router although nothing
  // used it, and the analyzer complained. The report gives no steps; assumed:
  // a page with a parameter whose type comes from dart:ui (a Locale and a
  // Size), then build the router. When the bug is real the source imports
  // dart:ui with nothing from it used, or does not compile. A page with no
  // dart:ui type must never get the import.
  group('dart:ui in the generated router (#132)', () {
    test('a page with no dart:ui type does not import it', () async {
      final result = await generateRouter({
        'lib/home_page.dart': _page(
          'HomePage',
          parameters: 'required this.title',
          fields: '  final String title;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, isNot(contains('dart:ui')));
    });

    test('a page with dart:ui types compiles', () async {
      final result = await generateRouter({
        'lib/canvas_page.dart': _page(
          'CanvasPage',
          parameters: 'required this.locale, required this.size',
          fields: '  final Locale locale;\n  final Size size;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });
  });
}
