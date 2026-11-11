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
  // #16: a route whose page takes a Stream parameter. The generated router
  // imported 'dart:async/stream.dart', which does not exist, so it did not
  // compile. Steps: a page with `final Stream<int> numbers`, then build the
  // router. When the bug is real the build fails or the source holds that
  // import.
  test(
    'a Stream parameter compiles without a dart:async/stream.dart import',
    () async {
      final result = await generateRouter({
        'lib/counter_page.dart': _page(
          'CounterPage',
          parameters: 'required this.numbers',
          fields: '  final Stream<int> numbers;',
          imports: "import 'dart:async';",
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, isNot(contains('dart:async/stream.dart')));
      expect(result.source, contains('Stream<int>'));
    },
  );
}
