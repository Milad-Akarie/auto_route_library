import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test RouteMatch Equality', () {
    final match = RouteMatch(
      config: TestRoute('Test'),
      segments: ['/'],
      stringMatch: '/',
      key: ValueKey('Test'),
      args: "Args",
      params: Parameters({"id": 1}),
      queryParams: Parameters({"foo": "bar"}),
      fragment: 'fragment',
      redirectedFrom: 'redirectedFrom',
      autoFilled: false,
      children: [
        RouteMatch(
          config: TestRoute('Test'),
          segments: ['/'],
          stringMatch: '/',
          key: ValueKey('Test'),
          args: "Args",
          params: Parameters({"id": 1}),
          queryParams: Parameters({"foo": "bar"}),
          fragment: 'fragment',
          redirectedFrom: 'redirectedFrom',
          autoFilled: false,
        )
      ],
    );
    expect(match, equals(match));
    expect(match, equals(match.copyWith()));
  });

  test('Test PageRouteInfo Equality', () {
    final pageRouteInfo = PageRouteInfo(
      'Test',
      args: "Args",
      rawPathParams: {"id": 1},
      rawQueryParams: {"foo": "bar"},
      initialChildren: [
        PageRouteInfo(
          'Test',
          args: "Args",
          rawPathParams: {"id": 1},
          rawQueryParams: {"foo": "bar"},
        )
      ],
      fragment: 'fragment',
    );

    expect(pageRouteInfo, equals(pageRouteInfo));
    expect(pageRouteInfo, equals(pageRouteInfo.copyWith()));
  });
}
