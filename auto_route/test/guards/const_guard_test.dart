import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/654
  // Reported: AutoRouteGuard had no const constructor, so a guard could not
  // have one either.
  // Should: a guard with a const constructor can be created in a const
  // expression, and a const route list can hold it.
  test('a guard with a const constructor is a compile-time constant', () {
    const guard = _ConstGuard();
    const same = _ConstGuard();

    expect(identical(guard, same), isTrue);
    expect(guard, isA<AutoRouteGuard>());
  });
}

class _ConstGuard extends AutoRouteGuard {
  const new();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}
