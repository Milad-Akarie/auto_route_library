import 'package:test/test.dart';

import 'support/generate.dart';

String _page(
  String name, {
  required String parameters,
  required String fields,
}) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key, $parameters});

$fields

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

void main() {
  // #371: a page whose only constructor parameter is `required Key key`
  // got a route with no `key` parameter and `const ConfigureStepPage()` as its
  // builder, so the router did not compile and
  // `ConfigureStepRoute(key: stepKeys[0])` was not possible. Steps: a page
  // with `const ConfigureStepPage({required Key key}) : super(key: key)` and no
  // other parameter, then build the router and check the route takes the key.
  // A page with only an optional `super.key` gets a route without it: the
  // maintainer left it out on purpose, as no page needs a key to be told
  // apart, and the second test pins that.
  test('a page with only a Key gives a route that takes the key', () async {
    final result = await generateRouter({
      'lib/configure_step.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class ConfigureStepPage extends StatefulWidget {
  const ConfigureStepPage({required Key key}) : super(key: key);

  @override
  State<ConfigureStepPage> createState() => _ConfigureStepPageState();
}

class _ConfigureStepPageState extends State<ConfigureStepPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      'lib/use_route.dart': '''
import 'package:flutter/widgets.dart';

import 'router.gr.dart';

final route = ConfigureStepRoute(key: GlobalKey());
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    final flat = result.source!.replaceAll(RegExp(r'_i\d+\.'), '');
    expect(flat, contains('ConfigureStepRoute({'));
    expect(flat, contains('Key key'));
  });

  test(
    'a page with only an optional super.key gets a route without it',
    () async {
      final result = await generateRouter({
        'lib/home_page.dart': _page('HomePage', parameters: '', fields: ''),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final flat = result.source!.replaceAll(RegExp(r'_i\d+\.'), '');
      expect(flat, contains('HomeRoute({List<PageRouteInfo>? children})'));
      expect(flat, contains('const HomePage()'));
    },
  );
}
