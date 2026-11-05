import 'package:test/test.dart';

import 'support/generate.dart';

/// A page library named [name] whose constructor takes [parameters], each
/// also declared as a field in [fields].
String _page(String name, {required String parameters, required String fields, String imports = ''}) =>
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

  // #629: the example's `@queryParam this.filter = 'none'` failed the build
  // with "QueryParams must be nullable or have default value", though it has a
  // default. #590: a bool with a default gave a `num?` type error.
  group('a query parameter with a default value (#629, #590)', () {
    test('builds with the default and reads the url by type', () async {
      final result = await generateRouter({
        'lib/my_books_page.dart': _page(
          'MyBooksPage',
          parameters: "@queryParam this.filter = 'none', @QueryParam('update') this.forUpdate = false",
          fields: '''
  final String filter;
  final bool forUpdate;''',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains("queryParams.getString('filter', 'none')"));
      expect(result.source, contains("queryParams.getBool('update', false)"));
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

  // Issue #2148 was an enum query parameter read with the untyped queryParams
  // get, which hands the url's string, rm from /cart?type=rm, to the enum
  // argument and throws a type error. It was also written into the url with
  // its toString, as MfUserCartTypes.rm. It is now written and read by name.
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
        source,
        contains("prices:queryParams.optList('prices')?.map(double.tryParse).whereType<double>().toList()"),
      );
      expect(source, contains("sizes:queryParams.optList('sizes')?.map(num.tryParse).whereType<num>().toList()"));
      expect(source, contains("flags:queryParams.optList('flags')?.map((text)=>text.toLowerCase()=='true'"));
      expect(source, contains("tags:queryParams.optList('tags')"));
      expect(
        source,
        contains("picked:queryParams.optList('picked')?.map(int.tryParse).whereType<int>().toList()??const[1,2]"),
      );
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
      expect(
        result.errors.join(),
        allOf(contains('a List query param can hold String, int, double, num, bool or enum'), contains('not Color')),
      );
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
      expect(result.errors.join(), contains('a List path param can hold String items, not int'));
    });
  });

  // flutter/flutter#157809: a url naming a value an enum does not have, as in
  // '/mode/bogus' for `enum Mode { light, dark }`, failed the build of the
  // page with "Bad state". An enum query param reads such a name as null
  // (test/enum_query_param in auto_route). An enum path param can't be
  // declared: the build stops with an error that names the param and the
  // types a path param can have, so no url reaches the page with a bad name.
  group('an enum path param (flutter/flutter#157809)', () {
    test('is a build error that names the param', () async {
      final result = await generateRouter({
        'lib/mode_page.dart': _page(
          'ModePage',
          imports: 'enum Mode { light, dark }',
          parameters: '@PathParam() required this.mode',
          fields: '  final Mode mode;',
        ),
      });
      expect(result.errors, hasLength(1));
      expect(
        result.errors.join(),
        allOf(
          contains('Parameter [mode] must be of a type that can be parsed from a [String]'),
          contains('valid types: [String, int, double, num, bool, dynamic]'),
        ),
      );
    });
  });
  // #1305: a page that takes a model from another library, as in "pass User
  // from screen A to screen B", made the generated router fail with
  // "Type 'User' not found" because the router file lacked the model's import.
  group('an argument typed by a model in another library (#1305)', () {
    test('gets its import in the generated router', () async {
      final result = await generateRouter({
        'lib/models/user.dart': 'class User {\n  User({this.name, this.age});\n  String? name;\n  String? age;\n}',
        'lib/screens/b_screen.dart': _page(
          'BScreen',
          imports: "import '../models/user.dart';",
          parameters: 'required this.user, this.friends = const []',
          fields: '  final User user;\n  final List<User> friends;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('User user'));
    });
  });

  // #1507: a page argument typed by a class from a file another builder
  // generates, such as graphql_codegen's `Query$Artist`, gave a router that
  // didn't compile, "Undefined class 'InvalidType'", when that file wasn't
  // written yet as auto_route's builder ran. The build now fails naming the
  // argument and how to order the builders.
  group('an argument whose type is not resolved (#1507)', () {
    for (final (label, type) in [('itself', r'Query$Artist?'), ('inside a type argument', r'List<Query$Artist>?')]) {
      test('fails the build naming the argument when the type is $label', () async {
        final result = await generateRouter({
          'lib/artist_page.dart': _page(
            'ArtistPage',
            imports: "import 'artist.graphql.dart';",
            parameters: 'this.artist',
            fields: '  final $type artist;',
          ),
        });
        expect(result.errors.join(), contains('The type of artist in ArtistPage could not be resolved'));
        expect(result.errors.join(), contains('runs_before'));
      });
    }
  });

  // Issue #1603 was a nullable Color argument that came out as a final
  // InvalidType field, an analyzer failure of the time. See
  // dart-lang/source_gen#650 and #1438.
  // A Color from dart:ui or Flutter keeps its type. Without an import it
  // fails the build with a message, as #1507 above.
  for (final import in ["import 'dart:ui';", "import 'package:flutter/painting.dart';"]) {
    test('a Color argument keeps its type with $import (#1603)', () async {
      final result = await generateRouter({
        'lib/webkit_screen.dart': _page(
          'WebkitScreen',
          imports: import,
          parameters: 'this.title, this.color',
          fields: '  final String? title;\n  final Color? color;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, matches(RegExp(r'final _i\d+\.Color\? color;')));
    });
  }

  // flutter/flutter#135591: go_router_builder cast a required
  // `List<({int id, String? name})>` extra to `List<({int id, String name})>`,
  // dropping the inner `?`, and the cast threw when the route opened.
  // auto_route doesn't cast an argument; its type is written as declared.
  test('a list of records with a nullable field keeps the field nullable (flutter/flutter#135591)', () async {
    final result = await generateRouter({
      'lib/items_page.dart': _page(
        'ItemsPage',
        parameters: 'required this.items',
        fields: '  final List<({int id, String? name})> items;',
      ),
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains('required List<({int id, String? name})> items'));
    expect(result.source, contains('final List<({int id, String? name})> items;'));
    expect(result.source, contains('data.argsAs<ItemsRouteArgs>()'));
  });

  // flutter/flutter#108437: a query param typed as a Set of String, an
  // Iterable of int, a DateTime or any type the url can't give was read with
  // the untyped queryParams get, so the router compiled and opening the page
  // from a link threw a TypeError, since the url gives text or a list of it. A Set or an
  // Iterable is now read as a List is; any other type fails the build.
  group('a Set or Iterable query param (flutter/flutter#108437)', () {
    test('is read from the url as its own type', () async {
      final result = await generateRouter({
        'lib/sort.dart': 'enum Sort { asc, desc }',
        'lib/tags_page.dart': _page(
          'TagsPage',
          imports: "import 'sort.dart';",
          parameters:
              '@QueryParam() this.tags = const {}, @QueryParam() this.ids, @QueryParam() this.sorts, '
              '@QueryParam() this.names',
          fields:
              '  final Set<String> tags;\n  final Iterable<int>? ids;\n  final Set<Sort>? sorts;\n'
              '  final Iterable<String>? names;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains("tags: queryParams.optList('tags')?.toSet() ?? const {}"));
      final source = result.source!.replaceAll(RegExp(r'\s+'), '');
      expect(source, contains("ids:queryParams.optList('ids')?.map(int.tryParse).whereType<int>().toList()"));
      expect(
        source,
        contains(
          "sorts:queryParams.optList('sorts')?.map((name)=>_i4.Sort.values.asNameMap()[name]).whereType<_i4.Sort>().toSet()",
        ),
      );
      expect(result.source, contains("names: queryParams.optList('names')"));
      expect(result.source, isNot(contains('queryParams.get(')));
    });

    for (final (type, field) in [
      ('DateTime', 'final DateTime? at;'),
      ('Uri', 'final Uri? at;'),
      ('ArticleId', 'final ArticleId? at;'),
    ]) {
      test('of another type, $type, fails the build naming the param', () async {
        final result = await generateRouter({
          'lib/article_id.dart': 'extension type const ArticleId(String value) {}',
          'lib/at_page.dart': _page(
            'AtPage',
            imports: "import 'article_id.dart';",
            parameters: '@QueryParam() this.at',
            fields: '  $field',
          ),
        });
        expect(
          result.errors.join(),
          contains('Parameter [at] is a @QueryParam of type $type, which a url can not give'),
        );
      });
    }

    test('of a type the url can not give is allowed when a required argument keeps links out', () async {
      final result = await generateRouter({
        'lib/at_page.dart': _page(
          'AtPage',
          parameters: 'required this.title, @QueryParam() this.at',
          fields: '  final String title;\n  final DateTime? at;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });

    test('of items the url can not give fails the build', () async {
      final result = await generateRouter({
        'lib/at_page.dart': _page('AtPage', parameters: '@QueryParam() this.at', fields: '  final Set<DateTime>? at;'),
      });
      expect(
        result.errors.join(),
        contains('at: a Set query param can hold String, int, double, num, bool or enum items'),
      );
    });
  });

  // flutter/flutter#170870: go_router_builder refused an extension type such
  // as `ArticleId`, over String, as a path parameter. auto_route takes one as
  // an argument, and as a path parameter fails the build naming the types a
  // path can give, as it does for any other type; reading one from the url
  // is not supported.
  group('an extension type argument (flutter/flutter#170870)', () {
    const articleId = 'extension type const ArticleId(String value) {}';

    test('is passed as it is', () async {
      final result = await generateRouter({
        'lib/article_id.dart': articleId,
        'lib/article_page.dart': _page(
          'ArticlePage',
          imports: "import 'article_id.dart';",
          parameters: 'required this.id',
          fields: '  final ArticleId id;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('required _i4.ArticleId id'));
    });

    test('as a path param fails the build naming the types a path can give', () async {
      final result = await generateRouter({
        'lib/article_id.dart': articleId,
        'lib/article_page.dart': _page(
          'ArticlePage',
          imports: "import 'article_id.dart';",
          parameters: '@PathParam() required this.id',
          fields: '  final ArticleId id;',
        ),
      });
      expect(result.errors.join(), contains('Parameter [id] must be of a type that can be parsed from a [String]'));
      expect(result.errors.join(), contains('valid types: [String, int, double, num, bool, dynamic]'));
    });
  });
}
