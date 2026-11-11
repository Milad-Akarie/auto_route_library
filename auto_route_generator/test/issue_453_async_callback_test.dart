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
  // #453: a route parameter whose type returns a Future, such as
  // Flutter's AsyncCallback or a typedef of `Future<void> Function()`, was
  // written as `Future<-> Function()`, so the build failed with "Could not
  // format because the source could not be parsed". Steps: a page with
  // `final AsyncCallback onAuth` (and a second with a typedef), then build
  // the router.
  group('an async callback parameter (#453)', () {
    test('AsyncCallback compiles', () async {
      final result = await generateRouter({
        'lib/sign_in_page.dart': _page(
          'SignInPage',
          parameters: 'required this.onAuth',
          fields: '  final AsyncCallback onAuth;',
          imports: "import 'package:flutter/foundation.dart';",
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, isNot(contains('<->')));
    });

    test('a typedef with a Future return type compiles', () async {
      final result = await generateRouter({
        'lib/callbacks.dart': 'typedef AuthCallback = Future<void> Function();',
        'lib/sign_in_page.dart': _page(
          'SignInPage',
          parameters: 'required this.onAuth',
          fields: '  final AuthCallback onAuth;',
          imports: "import 'callbacks.dart';",
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, isNot(contains('<->')));
    });

    test('an inline Future<void> Function() compiles', () async {
      final result = await generateRouter({
        'lib/sign_in_page.dart': _page(
          'SignInPage',
          parameters: 'required this.onAuth',
          fields: '  final Future<void> Function() onAuth;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, isNot(contains('<->')));
    });
  });
}
