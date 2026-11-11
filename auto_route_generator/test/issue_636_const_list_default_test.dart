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
  // #636: a page parameter `List<Color>` with a const list as its default
  // value got "Undefined name 'Color'" in the generated route, because the
  // route imported the library of a declaration named by an identifier in
  // the default, such as `Sort.asc`, and not of a class named by a
  // constructor call such as `Color(0xFF000000)`. A single `Color` default
  // worked. Steps: a page with
  // `this.colors = const [Color(0xFF000000), Color(0xFFFFFFFF)]`, then build
  // the router. The router must compile and keep the const default.
  // The default may name declarations from several libraries, such as a
  // `Color` and an enum value from a file of the app: each one gets its
  // import.
  group('a List<Color> parameter with a default (#636)', () {
    test('a const list default compiles and is kept', () async {
      final result = await generateRouter({
        'lib/palette_page.dart': _page(
          'PalettePage',
          parameters:
              'this.colors = const [Color(0xFF000000), Color(0xFFFFFFFF)]',
          fields: '  final List<Color> colors;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final flat = result.source!
          .replaceAll(RegExp(r'_i\d+\.'), '')
          .replaceAll(RegExp(r'\s+'), '');
      expect(flat, contains('Color(0xFF000000)'));
      expect(flat, contains('Color(0xFFFFFFFF)'));
    });

    test('a required List<Color> compiles', () async {
      final result = await generateRouter({
        'lib/palette_page.dart': _page(
          'PalettePage',
          parameters: 'required this.colors',
          fields: '  final List<Color> colors;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });

    test('a default naming declarations of two libraries compiles', () async {
      final result = await generateRouter({
        'lib/shade.dart': '''
enum Shade { light, dark }
''',
        'lib/palette_page.dart': _page(
          'PalettePage',
          parameters:
              'this.entries = const [Color(0xFF000000), Shade.dark, '
              "'Color Shade']",
          fields: '  final List<Object> entries;',
          imports: "import 'shade.dart';",
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final flat = result.source!
          .replaceAll(RegExp(r'_i\d+\.'), '')
          .replaceAll(RegExp(r'\s+'), '');
      expect(
        flat,
        contains("const[Color(0xFF000000),Shade.dark,'ColorShade']"),
      );
      expect(result.source, contains('package:app/shade.dart'));
    });
  });
}
