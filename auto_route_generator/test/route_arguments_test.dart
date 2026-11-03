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

  // #2106: a function type inside a type argument, such as
  // `Option<void Function(String url)>`, came out as `Option<void>`, so the
  // generated route did not compile.
  group('a function type inside a type argument (#2106)', () {
    test('keeps its parameters and their imports', () async {
      final result = await generateRouter({
        'lib/option.dart': '''
class Option<T> {
  const Option.none();
}

class UrlChange {}

typedef UrlCallback = void Function(String url);
''',
        'lib/web_view_page.dart': _page(
          'AppWebViewListenerPage',
          imports: "import 'option.dart';",
          parameters: '''
required this.url,
    this.onUrlChange = const Option.none(),
    this.onPageFinished = const Option.none(),
    this.onRequest = const Option.none(),
    this.onPageStarted = const Option.none(),
    this.onFrame = const Option.none(),''',
          fields: '''
  final String url;
  final Option<void Function(UrlChange change)> onUrlChange;
  final Option<void Function(String url)?> onPageFinished;
  final Option<bool Function(String url, [int? code])> onRequest;
  final Option<void Function({required bool isMainFrame, int? code})> onFrame;
  final Option<UrlCallback> onPageStarted;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = result.source!.replaceAll(RegExp(r'_i\d+\.'), '');
      expect(source, contains('Option<void Function(UrlChange)> onUrlChange'));
      expect(source, contains('Option<void Function(String)?> onPageFinished'));
      expect(source, contains('Option<bool Function(String, [int?])> onRequest'));
      expect(source, contains('Option<void Function({required bool isMainFrame, int? code})> onFrame'));
      expect(source, contains('Option<UrlCallback> onPageStarted'));
    });
  });

  // #2053: a path parameter typed by a typedef of `int` failed the build with
  // "Parameter [inboxMessageId] must be of a type that can be parsed from a
  // [String]": the generator checked the typedef's name, not its type.
  group('a url parameter typed by a typedef (#2053)', () {
    test('is parsed by the type the typedef stands for', () async {
      final result = await generateRouter({
        'lib/types.dart': 'typedef TypedefParameter = int;',
        'lib/inbox_page.dart': _page(
          'InboxMessageDetailsPage',
          imports: "import 'types.dart';",
          parameters: '@PathParam() required this.inboxMessageId, @QueryParam() this.page',
          fields: '''
  final TypedefParameter inboxMessageId;
  final TypedefParameter? page;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains("pathParams.getInt('inboxMessageId')"));
      expect(result.source, contains("queryParams.optInt('page')"));
    });
  });
}
