import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_router/router.dart';

// Apps can name the type of `router.navigationHistory` from the public
// import alone: write `final NavigationHistory history =
// router.navigationHistory;` and pass it to a helper. Before the export, this
// file did not compile.
int _countEntries(NavigationHistory history) => history.length;

void main() {
  test(
    'NavigationHistory can be named through package:auto_route/auto_route.dart',
    () {
      final router = SimpleRouter();
      // The type is named by _countEntries, which compiles only while it is
      // exported.
      final history = router.navigationHistory;

      expect(_countEntries(history), history.length);
      expect(history, same(router.navigationHistory));
    },
  );
}
