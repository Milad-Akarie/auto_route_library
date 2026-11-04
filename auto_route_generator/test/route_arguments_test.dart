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

  // #1968: a default value naming a function from another library, as in
  // `this.titleResolver = defaultTitleResolver`, was written into the route
  // without that library's import: "Undefined name 'defaultTitleResolver'".
  group('a default value from another library (#1968)', () {
    test('is imported', () async {
      final result = await generateRouter({
        'lib/defaults.dart': '''
String defaultTitleResolver() => 'Home screen';

const firstPage = 1;
''',
        'lib/home_screen.dart': _page(
          'HomeScreen',
          imports: "import 'defaults.dart';",
          parameters: 'this.titleResolver = defaultTitleResolver, @QueryParam() this.page = firstPage',
          fields: '''
  final String Function() titleResolver;
  final int page;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, matches(RegExp(r'titleResolver = _i\d+\.defaultTitleResolver')));
      expect(result.source, matches(RegExp(r"queryParams.getInt\('page', _i\d+\.firstPage\)")));
    });
  });

  // #2148: an enum query parameter was read with `queryParams.get('type')`,
  // which hands the url's string ('rm' from /cart?type=rm) to the enum
  // argument and throws a type error. It was also written into the url with
  // toString(), as `MfUserCartTypes.rm`. It is now written and read by name.
  group('an enum query parameter (#2148)', () {
    test('is read and written by its name', () async {
      final result = await generateRouter({
        'lib/types.dart': 'enum MfUserCartTypes { rm, mf }',
        'lib/cart_page.dart': _page(
          'MfUserCartView',
          imports: "import 'types.dart';",
          parameters: "@QueryParam('type') required this.userCartType, @QueryParam() this.sort = MfUserCartTypes.mf",
          fields: '''
  final MfUserCartTypes? userCartType;
  final MfUserCartTypes sort;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = result.source!
          .replaceAll(RegExp(r'_i\d+\.'), '')
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r',(?=[)}\]])'), '');
      expect(source, contains("rawQueryParams:{'type':userCartType?.name,'sort':sort.name}"));
      expect(source, contains("userCartType:MfUserCartTypes.values.asNameMap()[queryParams.optString('type')]"));
      expect(
        source,
        contains("sort:MfUserCartTypes.values.asNameMap()[queryParams.optString('sort')]??MfUserCartTypes.mf"),
      );
    });
  });

  // A default value is a const expression when its code starts with `const`.
  // One that only contains the text, such as the constant `constTitle`, was
  // written into the args class as `const Title`: "Undefined class 'Title'".
  group('a default value named after const', () {
    test('is written as it is', () async {
      final result = await generateRouter({
        'lib/defaults.dart': '''
const constTitle = 'Home';
''',
        'lib/home_screen.dart': _page(
          'HomeScreen',
          imports: "import 'defaults.dart';",
          parameters: 'this.title = constTitle',
          fields: '  final String title;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, matches(RegExp(r'this\.title = _i\d+\.constTitle')));
    });

    test('keeps a const value const', () async {
      final result = await generateRouter({
        'lib/defaults.dart': '''
class Range {
  final int low;
  const Range(this.low);
}
''',
        'lib/home_screen.dart': _page(
          'HomeScreen',
          imports: "import 'defaults.dart';",
          parameters: 'this.range = const Range(1), this.tags = const <String>[]',
          fields: '''
  final Range range;
  final List<String> tags;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, matches(RegExp(r'this\.range = const _i\d+\.Range\(1\)')));
    });
  });

  // #2061: a query parameter of type List<int> was read with
  // `queryParams.optList('ids')`, which returns List<String>?, so the
  // generated router didn't compile: "The argument type 'List<String>?'
  // can't be assigned to the parameter type 'List<int>?'". The build gave no
  // error. Lists of int, double, num, bool and an enum are read and written
  // as items of the right type; enums by name.
  group('a list query parameter (#2061)', () {
    test('of int, double, num, bool or an enum compiles', () async {
      final result = await generateRouter({
        'lib/types.dart': 'enum Sort { asc, desc }',
        'lib/list_page.dart': _page(
          'ListPage',
          imports: "import 'types.dart';",
          parameters: '''
@QueryParam() this.ids,
    @QueryParam() this.prices,
    @QueryParam() this.sizes,
    @QueryParam() this.flags,
    @QueryParam() this.sorts,
    @QueryParam() this.tags,
    @QueryParam() this.picked = const [1, 2],
    @QueryParam() this.orders = const []''',
          fields: '''
  final List<int>? ids;
  final List<double>? prices;
  final List<num>? sizes;
  final List<bool>? flags;
  final List<Sort>? sorts;
  final List<String>? tags;
  final List<int> picked;
  final List<Sort> orders;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = result.source!
          .replaceAll(RegExp(r'_i\d+\.'), '')
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r',(?=[)}\]])'), '');
      expect(source, contains("ids:queryParams.optList('ids')?.map(int.tryParse).whereType<int>().toList()"));
      expect(
          source, contains("prices:queryParams.optList('prices')?.map(double.tryParse).whereType<double>().toList()"));
      expect(source, contains("sizes:queryParams.optList('sizes')?.map(num.tryParse).whereType<num>().toList()"));
      expect(source, contains("flags:queryParams.optList('flags')?.map((text)=>text.toLowerCase()=='true'"));
      expect(source, contains("tags:queryParams.optList('tags')"));
      expect(source,
          contains("picked:queryParams.optList('picked')?.map(int.tryParse).whereType<int>().toList()??const[1,2]"));
      expect(
        source,
        contains(
          "sorts:queryParams.optList('sorts')?.map((name)=>Sort.values.asNameMap()[name]).whereType<Sort>().toList()",
        ),
      );
      expect(source, contains("'sorts':sorts?.map((item)=>item.name).toList()"));
      expect(source, contains("'orders':orders.map((item)=>item.name).toList()"));
    });

    test('of another type is a build error', () async {
      final result = await generateRouter({
        'lib/list_page.dart': _page(
          'ListPage',
          imports: "import 'dart:ui';",
          parameters: '@QueryParam() this.colors',
          fields: '  final List<Color>? colors;',
        ),
      });
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('a List query param can hold String, int, double, num, bool or enum'));
      expect(result.errors.single, contains('not Color'));
    });

    test('of ints as a path param is a build error', () async {
      final result = await generateRouter({
        'lib/list_page.dart': _page(
          'ListPage',
          parameters: '@PathParam() required this.ids',
          fields: '  final List<int> ids;',
        ),
      });
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('a List path param can hold String items, not int'));
    });
  });
}
