import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Runs every headless test with Flutter's leak tracking, so a disposable
/// object the router creates and never disposes fails the test file that made
/// it. Add `.withCreationStackTrace()` to the settings to see where a leaked
/// object was created.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnored(
    notDisposed: {
      // Leaks in auto_route, each removed by the commit that fixes it.
      // AutoTabsRouter.pageView never disposes the PageController it creates.
      'PageController': null,
      // AutoTabsRouter's indexed stack never disposes its CurvedAnimation.
      'CurvedAnimation': null,
      // A StackRouter never disposes its ActiveGuardObserver.
      'ActiveGuardObserver': null,
      // Disposing a RootStackRouter leaves its delegate, url provider and
      // navigation history undisposed.
      'AutoRouterDelegate': null,
      'AutoRouteInformationProvider': null,
      'NavigationHistoryImpl': null,

      // Objects the tests create and never dispose: the root routers, with
      // the observer each one creates, and the notifiers that drive guard
      // reevaluation.
      '_RootStackRouterImpl': null,
      'BackGestureRouter': null,
      'CartRouter': null,
      'ListRouter': null,
      'NestedRouter': null,
      'NestedTabsRouter': null,
      'ObserverRouter': null,
      'SimpleRouter': null,
      'TabsScaffoldRouter': null,
      'WrapperRouter': null,
      '_AppRouter': null,
      '_PopScopeHostRouter': null,
      'PagelessRoutesObserver': null,
      'GuardChangeNotifier': null,
      'ValueNotifier<int>': null,
      'ValueNotifier<bool>': null,
      'ValueNotifier<List<PageRouteInfo<Object?>>>': null,
      '_AuthRepo': null,
      '_AuthStore': null,
      '_StreamReevaluateListenable': null,
    },
  );
  await testMain();
}
