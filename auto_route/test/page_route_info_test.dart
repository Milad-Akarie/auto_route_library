import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PageRouteInfo equality test', () {
    PageRouteInfo build(String name) => .new(
      name,
      rawPathParams: const {'foo': 'baz'},
      rawQueryParams: const {'foo': 'bar'},
      args: 'Args',
      initialChildren: const [PageRouteInfo('sub')],
    );
    final first = build('Name');
    final second = build('Name');
    expect(first == second, true);
  });

  test('Calling PageRouteInfo.fromRedirect on an redirected instance should return true', () {
    expect(const PageRouteInfo('Name', redirectedFrom: '/redirect').fromRedirect, true);
  });

  test('Calling PageRouteInfo.pathParams should return Parameters instance with rawPathParams', () {
    expect(const PageRouteInfo('Name', rawPathParams: {'foo': 'bar'}).pathParams, const Parameters({'foo': 'bar'}));
  });

  test('Calling PageRouteInfo.queryParams should return Parameters instance with rawQueryParams', () {
    expect(const PageRouteInfo('Name', rawQueryParams: {'foo': 'bar'}).queryParams, const Parameters({'foo': 'bar'}));
  });

  test('Calling PageRouteInfo.copyWith with no params should return identically instance', () {
    const instance = PageRouteInfo('Name', redirectedFrom: '/redirect');
    expect(instance.copyWith() == instance, true);
  });

  test('Calling PageRouteInfo.flattened should return list of flattened children', () {
    expect(
      const PageRouteInfo(
        'Name',
        initialChildren: [
          PageRouteInfo('Sub1', initialChildren: [PageRouteInfo('Sub2')]),
        ],
      ).flattened,
      const [
        PageRouteInfo(
          'Name',
          initialChildren: [
            PageRouteInfo('Sub1', initialChildren: [PageRouteInfo('Sub2')]),
          ],
        ),
        PageRouteInfo('Sub1', initialChildren: [PageRouteInfo('Sub2')]),
        PageRouteInfo('Sub2'),
      ],
    );
  });

  // #1163: a path parameter named with a `$`, such as `user$id`, stayed in
  // the url as written, '/users/:user$id': its name went into a pattern
  // unescaped, where `$` means the end of the text.
  test(r'expandPath fills in a path parameter named with a $ (#1163)', () {
    expect(PageRouteInfo.expandPath(r'/users/:user$id', {r'user$id': '8'}), '/users/8');
  });

  // Routes with list or set url params, built twice with equal values, were unequal: equality compared
  // the params' values by identity, so two lists holding 'a' differed unless they were one list.
  group('PageRouteInfo with equal list or set params', () {
    PageRouteInfo route(Object tags) => .new('Tags', rawPathParams: {'tags': tags}, rawQueryParams: {'q': tags});

    test('are equal and hash equally when the params are equal lists', () {
      final a = route(['a', 'b']);
      final b = route(['a', 'b']);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('are equal and hash equally when the params are equal sets', () {
      final a = route({'a', 'b'});
      final b = route({'b', 'a'});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differ when the lists differ', () {
      expect(route(['a']), isNot(equals(route(['b']))));
    });
  });

  // With path params 'id' and 'idx', '/a/:idx' expanded to '/a/1x': the pattern ':(id|idx)' had no segment end,
  // so ':id' matched the start of ':idx' and its value replaced it, keeping the 'x'.
  group('PageRouteInfo.expandPath with a param whose name starts another', () {
    test('expands the longer name whole', () {
      expect(PageRouteInfo.expandPath('/a/:idx', {'id': '1', 'idx': '2'}), '/a/2');
    });

    test('expands both names in one path', () {
      expect(PageRouteInfo.expandPath('/a/:id/b/:idx', {'id': '1', 'idx': '2'}), '/a/1/b/2');
    });

    test('keeps a param that has no value whole', () {
      expect(PageRouteInfo.expandPath('/a/:idx', {'id': '1'}), '/a/:idx');
    });
  });
}
