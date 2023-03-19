import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("PageRouteInfo equality test", () {
    expect(
      const PageRouteInfo(
            'Name',
            rawPathParams: {'foo': 'baz'},
            rawQueryParams: {'foo': 'bar'},
            args: 'Args',
            initialChildren: [
              PageRouteInfo('sub'),
            ],
          ) ==
          const PageRouteInfo(
            'Name',
            rawPathParams: {'foo': 'baz'},
            rawQueryParams: {'foo': 'bar'},
            args: 'Args',
            initialChildren: [PageRouteInfo('sub')],
          ),
      true,
    );
  });

  test("Calling PageRouteInfo.fromRedirect on an redirected instance should return true", () {
    expect(const PageRouteInfo('Name', redirectedFrom: '/redirect').fromRedirect, true);
  });

  test("Calling PageRouteInfo.pathParams should return Parameters instance with rawPathParams", () {
    expect(const PageRouteInfo('Name', rawPathParams: {'foo': 'bar'}).pathParams, const Parameters({'foo': 'bar'}));
  });

  test("Calling PageRouteInfo.queryParams should return Parameters instance with rawQueryParams", () {
    expect(const PageRouteInfo('Name', rawQueryParams: {'foo': 'bar'}).queryParams, const Parameters({'foo': 'bar'}));
  });

  test("Calling PageRouteInfo.copyWith with no params should return identically instance", () {
    const instance = PageRouteInfo('Name', redirectedFrom: '/redirect');
    expect(instance.copyWith() == instance, true);
  });

  test("Calling PageRouteInfo.flattened should return list of flattened children", () {
    expect(
        const PageRouteInfo(
          'Name',
          initialChildren: [
            PageRouteInfo(
              'Sub1',
              initialChildren: [
                PageRouteInfo('Sub2'),
              ],
            ),
          ],
        ).flattened,
        const [
          PageRouteInfo(
            'Name',
            initialChildren: [
              PageRouteInfo(
                'Sub1',
                initialChildren: [
                  PageRouteInfo('Sub2'),
                ],
              ),
            ],
          ),
          PageRouteInfo(
            'Sub1',
            initialChildren: [
              PageRouteInfo('Sub2'),
            ],
          ),
          PageRouteInfo('Sub2'),
        ]);
  });
}
