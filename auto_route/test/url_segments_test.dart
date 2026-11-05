import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

// How the matcher splits a url's path into segments, on every platform: at
// each '/', with the root first, empty segments skipped and escapes kept, so
// an encoded '/' stays inside its segment.
void main() {
  final matcher = RouteMatcher(
    RouteCollection.fromList([
      TestRoute('HomeRoute', path: '/'),
      TestRoute('BookRoute', path: '/books/:id', fullMatch: true),
      TestRoute(
        'ShelfRoute',
        path: '/shelf/:id',
        children: [TestRoute('ShelfItemRoute', path: 'item')],
      ),
      TestRoute('DriveRoute', path: '/:drive/files'),
      TestRoute('FolderRoute', path: r'/folders\docs'),
    ], root: true),
  );

  RouteMatch<Object?> matchOf(String url) {
    final [match] = matcher.matchUri(Uri.parse(url))!;
    return match;
  }

  test('the root is its own segment', () {
    final match = matchOf('/');
    expect(match.name, 'HomeRoute');
    expect(match.segments, ['/']);
    expect(match.stringMatch, '/');
  });

  test('empty segments and a trailing slash are skipped', () {
    final match = matchOf('/books//7/');
    expect(match.name, 'BookRoute');
    expect(match.segments, ['/', 'books', '7']);
    expect(match.stringMatch, '/books/7');
    expect(match.params.getString('id'), '7');
  });

  test('an encoded slash stays inside its segment', () {
    final match = matchOf('/books/a%2Fb');
    expect(match.segments, ['/', 'books', 'a%2Fb']);
    expect(match.stringMatch, '/books/a%2Fb');
    expect(match.params.getString('id'), 'a/b');
    expect(matcher.matchUri(Uri.parse('/books/a%2Fb/c')), isNull);
  });

  test('a nested router gets the rest of the url, with its encoded slash', () {
    final match = matchOf('/shelf/a%2Fb/item');
    expect(match.stringMatch, '/shelf/a%2Fb');
    expect(match.params.getString('id'), 'a/b');
    expect(match.children!.singleOrNull?.name, 'ShelfItemRoute');
  });

  // On the web the path package rejoined the segments as urls, where a first
  // segment ending in ':' read as a scheme and lost its leading '/'.
  test('a first segment ending in a colon keeps its leading slash', () {
    final match = matchOf('/c:/files');
    expect(match.name, 'DriveRoute');
    expect(match.stringMatch, '/c:/files');
    expect(match.params.getString('drive'), 'c:');
    expect(UrlState.fromSegments([match]).url, '/c:/files');
  });

  // A backslash is no separator on any platform; on Windows the path package
  // split at it too.
  test('a backslash in a route path stays inside its segment', () {
    final match = matchOf('/folders%5Cdocs');
    expect(match.name, 'FolderRoute');
    expect(match.segments, ['/', 'folders%5Cdocs']);
    expect(match.stringMatch, '/folders%5Cdocs');
  });
}
