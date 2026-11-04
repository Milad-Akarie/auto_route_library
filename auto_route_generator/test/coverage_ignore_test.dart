import 'package:test/test.dart';

import 'support/generate.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/945
  // Generate a router. Its file should open with the comment
  // `coverage:ignore-file`, so test coverage reports leave generated code out.
  test('the generated router opens with the coverage:ignore-file comment', () async {
    final result = await generateRouter({
      'lib/home_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.source, contains('// coverage:ignore-file'));
    expect(result.source!.indexOf('// coverage:ignore-file'), lessThan(result.source!.indexOf('class ')));
  });
}
