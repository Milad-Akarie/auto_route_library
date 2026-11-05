// Times the url work auto_route does on every navigation: matching a url
// against the routes, matching a route by name, and building the url back.
//
// auto_route needs Flutter, so this runs through the Flutter test runner,
// which in Chrome only serves files under test/. The name has no `_test`, so
// a plain `flutter test` leaves it out. From auto_route/:
//
//   flutter test test/benchmark/url_benchmark.dart
//   flutter test test/benchmark/url_benchmark.dart --platform chrome
//
// Each case prints one line, `RESULT <case> <microseconds per run>`.
// summarize.dart, next to this file, turns several runs into medians and
// spreads. The runner runs the VM in JIT mode with asserts on, so the numbers
// are for comparing two versions of the code on one machine, not for apps.

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// A benchmark the runner runs only when named, so not a `_test` file.
// ignore: prefer-correct-test-file-name
void main() {
  test('url benchmark', () {
    final benchmarks = <BenchmarkBase>[
      for (final count in [10, 100, 1000]) ...[
        _Benchmark('match.flat.$count.first', _flatMatcher(count), (matcher) => matcher.match('/page0')),
        _Benchmark('match.flat.$count.last', _flatMatcher(count), (matcher) => matcher.match('/page${count - 1}')),
      ],
      _Benchmark(
        'match.flat.1000.miss',
        _flatMatcher(1000),
        (matcher) => matcher.match('/missing') == null ? 'no match' : null,
      ),
      _Benchmark('match.deep.5', _deepMatcher, (matcher) => matcher.match(_deepUrl)),
      _Benchmark('match.query.12', _flatMatcher(10), (matcher) => matcher.match('/page9?$_kQuery')),
      _Benchmark('match.byRoute.deep.5', _deepMatcher, (matcher) => matcher.matchByRoute(_deepRoute)),
      _Benchmark('match.buildPathTo.deep.5', _deepMatcher, (matcher) => matcher.buildPathTo(_deepestRoute)),
      _Benchmark('urlState.deep.5', _deepMatcher, (_) => UrlState.fromSegments(_deepMatches).url),
      _Benchmark('urlState.query.12', _deepMatcher, (_) => UrlState.fromSegments(_queryMatches).url),
    ];
    for (final benchmark in benchmarks) {
      final microseconds = benchmark.measure();
      // The runner shows what a test prints; this is the benchmark's output.
      // ignore: avoid_print
      print('RESULT ${benchmark.name} ${microseconds.toStringAsFixed(3)}');
    }
  }, timeout: .none);
}

/// Runs [onRun] against [matcher], reporting microseconds per run.
class _Benchmark extends BenchmarkBase {
  const _Benchmark(super.name, this.matcher, this.onRun);

  final RouteMatcher matcher;
  final Object? Function(RouteMatcher matcher) onRun;

  @override
  void run() {
    if (onRun(matcher) == null) throw StateError('$name matched nothing');
  }

  // One run per exercise, so the score is microseconds per run.
  @override
  void exercise() => run();
}

/// A router with [count] routes side by side: '/page0', '/page1' and so on.
RouteMatcher _flatMatcher(int count) => .new(
  RouteCollection.fromList([
    for (var i = 0; i < count; i++) NamedRouteDef(name: 'Page$i', path: '/page$i', builder: (_, _) => const SizedBox()),
  ], root: true),
);

const _kDepth = 5;
const _kSiblings = 10;

/// Routes [_kDepth] levels deep. Each level has [_kSiblings] routes, the last
/// of which takes an id and holds the next level: '/level0-9/:id0/level1-9/:id1'.
final _deepMatcher = RouteMatcher(RouteCollection.fromList(_level(0), root: true));

List<AutoRoute> _level(int depth) => [
  for (var i = 0; i < _kSiblings; i++)
    NamedRouteDef(
      name: 'Level$depth-$i',
      path: '${depth == 0 ? '/' : ''}level$depth-$i/:id$depth',
      builder: (_, _) => const SizedBox(),
      children: depth < _kDepth - 1 && i == _kSiblings - 1 ? _level(depth + 1) : null,
    ),
];

final _deepUrl = '/${[for (var depth = 0; depth < _kDepth; depth++) 'level$depth-${_kSiblings - 1}/$depth'].join('/')}';

final List<RouteMatch<Object?>> _deepMatches =
    _deepMatcher.match(_deepUrl)?.lastOrNull?.flattened ?? (throw StateError('$_deepUrl matched nothing'));

const _kQuery =
    'search=blue%20shoes&page=2&sort=price&order=asc&size=9&color=blue&brand=acme&tag=new&tag=sale'
    '&min=10&max=90&ref=home';

final List<RouteMatch<Object?>> _queryMatches = _flatMatcher(10).match('/page9?$_kQuery')!;

PageRouteInfo _deepRouteFrom(int depth) => .new(
  'Level$depth-${_kSiblings - 1}',
  rawPathParams: {'id$depth': '$depth'},
  initialChildren: depth < _kDepth - 1 ? [_deepRouteFrom(depth + 1)] : null,
);

final PageRouteInfo _deepRoute = _deepRouteFrom(0);

final PageRouteInfo _deepestRoute = .new(
  'Level${_kDepth - 1}-${_kSiblings - 1}',
  rawPathParams: {for (var depth = 0; depth < _kDepth; depth++) 'id$depth': '$depth'},
);
