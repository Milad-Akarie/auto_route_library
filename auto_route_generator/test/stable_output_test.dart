import 'package:test/test.dart';

import 'support/generate.dart';

String _page(String name, String field) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key, required this.$field});

  final String $field;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

void main() {
  final pages = {
    'lib/a_zeta_page.dart': _page('ZetaPage', 'zeta'),
    'lib/z_alpha_page.dart': _page('AlphaPage', 'alpha'),
    'lib/mid_page.dart': _page('MidPage', 'mid'),
  };

  // #1513: the generated file was kept in version control and changed with
  // no code change, because the order of the routes and of the import aliases
  // followed the order build_runner visited the files in.
  test('the generated router is the same whatever order the files are visited in (#1513)', () async {
    final forward = await generateRouter(pages);
    final reversed = await generateRouter({
      for (final key in pages.keys.toList().reversed) key: pages[key]!,
    });
    expect(forward.errors, isEmpty);
    expect(forward.source, isNotNull);
    expect(reversed.source, forward.source);
    final source = forward.source!;
    expect(
      source.indexOf('class AlphaRoute '),
      lessThan(source.indexOf('class MidRoute ')),
    );
    expect(
      source.indexOf('class MidRoute '),
      lessThan(source.indexOf('class ZetaRoute ')),
    );
  });

  // #1636: generated route args had no == and hashCode, so a popUntil
  // predicate could not compare `previous.settings.arguments == route.args`.
  test('route args define == and hashCode by default (#1636)', () async {
    final result = await generateRouter({
      'lib/alpha_page.dart': _page('AlphaPage', 'alpha'),
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains('operator ==('));
    expect(result.source, contains('int get hashCode'));
  });
}
