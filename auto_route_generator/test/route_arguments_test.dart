import 'package:test/test.dart';

import 'support/generate.dart';

/// A page library named [name] whose constructor takes [parameters], each
/// also declared as a field in [fields].
String _page(String name, {String imports = '', required String parameters, required String fields}) => '''
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
  // #1801: a route argument whose record type holds another record failed
  // the build with "Type 'void' can't have type arguments": the inner record
  // was written as `void<String, String>`.
  group('a record argument holding a record (#1801)', () {
    test('compiles when the record is written inline', () async {
      final result = await generateRouter({
        'lib/card_page.dart': _page(
          'CardPage',
          parameters: 'required this.card',
          fields: '  final ({String id, bool isActivated, ({String id, String name})? resource}) card;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('({String id, String name})? resource'));
    });

    test('compiles when the record is a typedef', () async {
      final result = await generateRouter({
        'lib/card.dart': 'typedef Card = ({String id, bool isActivated, ({String id, String name})? resource});',
        'lib/card_page.dart': _page(
          'CardPage',
          imports: "import 'card.dart';",
          parameters: 'required this.card',
          fields: '  final Card card;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });
  });
}
