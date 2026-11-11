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
  // a page with a parameter whose type comes from dart:ui, then build the
  // router. When the bug is real the generated source imports dart:ui, with
  // nothing from it used, or does not compile. The generated router must
  // name each type through the library the app can reach it by (here
  // package:flutter), never through dart:ui, and must compile. A page with no
  // dart:ui type must never get the import either.
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

    test('a Locale and a Size come through package:flutter', () async {
      final result = await generateRouter({
        'lib/canvas_page.dart': _page(
          'CanvasPage',
          parameters: 'required this.locale, required this.size',
          fields: '  final Locale locale;\n  final Size size;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, isNot(contains('dart:ui')));
      expect(
        result.source,
        contains("import 'package:flutter/widgets.dart' as _i3;"),
      );
      expect(result.source, contains('required _i3.Locale locale'));
      expect(result.source, contains('required _i3.Size size'));
    });

    test(
      'a page that imports dart:ui does not make the router do so',
      () async {
        final result = await generateRouter({
          'lib/dispatch_page.dart': _page(
            'DispatchPage',
            parameters: 'required this.dispatcher',
            fields: '  final PlatformDispatcher dispatcher;',
            imports: "import 'dart:ui';",
          ),
        });
        expect(result.errors, isEmpty);
        expect(result.compileErrors, isEmpty);
        expect(result.source, isNot(contains('dart:ui')));
        expect(
          result.source,
          contains("import 'package:flutter/foundation.dart' as _i4;"),
        );
        expect(result.source, contains('required _i4.PlatformDispatcher'));
      },
    );
  });
}
