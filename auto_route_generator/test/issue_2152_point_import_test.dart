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
  // #2152: a page that takes a list of integer points got the Point class
  // imported from dart:html instead of dart:math, which does not compile on
  // mobile. dart:html re-exports Point and both libraries are loaded in the
  // build, so the first one found won. Steps: a page that imports dart:math
  // and takes that list, then build the router. The router must import
  // dart:math, the library that declares Point.
  test('Point comes from dart:math, not dart:html', () async {
    final result = await generateRouter({
      'lib/path_page.dart': _page(
        'PathPage',
        parameters: 'required this.points',
        fields: '  final List<Point<int>> points;',
        imports: "import 'dart:math';",
      ),
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, isNot(contains('dart:html')));
    expect(result.source, contains('dart:math'));
  });
}
