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
  // #75: the report has no body; its title says AutoRoute does not import
  // from dart:io, and it points at #74 (not available). Assumed steps: a
  // page with a `File` parameter from dart:io, then build the router. When
  // the bug is real the generated router does not import dart:io and does
  // not compile.
  test('a File parameter keeps its dart:io import', () async {
    final result = await generateRouter({
      'lib/photo_page.dart': _page(
        'PhotoPage',
        parameters: 'required this.file',
        fields: '  final File file;',
        imports: "import 'dart:io';",
      ),
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains("import 'dart:io'"));
  });
}
