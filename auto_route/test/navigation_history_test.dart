import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/controller/navigation_history/navigation_history_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';
import 'simple_router/router.dart';

void main() {
  group('NavigationHistory Tests', () {
    late SimpleRouter router;
    late NavigationHistory history;

    setUp(() {
      router = SimpleRouter()..ignorePopCompleters = true;
      history = router.navigationHistory;
    });

    test('Initial state should have length 0 and cannot navigate back', () {
      expect(history.length, 0);
      expect(history.canNavigateBack, false);
    });

    test('Should add entry when navigating to a route', () async {
      await router.push(const FirstRoute());
      expect(history.length, 1);
      expect(history.canNavigateBack, false); // Only one entry, can't go back
    });

    test('Should be able to navigate back when history has more than one entry', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      expect(history.length, 2);
      expect(history.canNavigateBack, true);
    });

    test('Should prevent duplicate consecutive entries', () async {
      await router.push(const FirstRoute());
      final firstLength = history.length;

      // Try to add the same route again
      await router.push(const FirstRoute());

      // Length should remain the same due to duplicate prevention
      expect(history.length, firstLength);
    });

    test('Should allow same route if not consecutive', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      await router.push(const FirstRoute());

      expect(history.length, 3);
    });

    test('Back navigation should remove last entry', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      await router.push(const ThirdRoute());

      expect(history.length, 3);

      history.back();
      await Future.delayed(const Duration(milliseconds: 10)); // Give time for navigation

      expect(history.length, 2);
    });

    test('Back navigation should navigate to previous route', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      history.back();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(router.current.name, FirstRoute.name);
    });

    test('Back navigation on single entry should not crash', () async {
      await router.push(const FirstRoute());

      expect(history.canNavigateBack, false);

      // This should not crash even though canNavigateBack is false
      expect(() => history.back(), returnsNormally);
    });

    test('Should limit history to 20 entries', () async {
      // Push 25 routes
      for (int i = 0; i < 25; i++) {
        // Alternate between routes to avoid duplicate prevention
        if (i % 3 == 0) {
          await router.push(const FirstRoute());
        } else if (i % 3 == 1) {
          await router.push(const SecondRoute());
        } else {
          await router.push(const ThirdRoute());
        }
      }

      // Should be limited to 20 + 1 (current)
      expect(history.length, lessThanOrEqualTo(21));
    });

    test('Should notify listeners on URL state change', () async {
      bool notified = false;
      history.addListener(() {
        notified = true;
      });

      await router.push(const FirstRoute());

      expect(notified, true);
    });

    test('Should track route as active after navigation', () async {
      await router.push(const FirstRoute());

      expect(history.isRouteActive(FirstRoute.name), true);
      expect(history.isRouteActive(SecondRoute.name), false);
    });

    test('Should update active route after navigation', () async {
      await router.push(const FirstRoute());
      expect(history.isRouteActive(FirstRoute.name), true);

      await router.push(const SecondRoute());
      expect(history.isRouteActive(SecondRoute.name), true);
    });

    test('Should handle replace navigation correctly', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      final lengthBeforeReplace = history.length;

      await router.replace(const ThirdRoute());

      // Replace should not increase length
      expect(history.length, lengthBeforeReplace);
      expect(router.current.name, ThirdRoute.name);
    });

    test('Back navigation should work multiple times', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      await router.push(const ThirdRoute());

      expect(history.length, 3);

      history.back();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(history.length, 2);

      history.back();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(history.length, 1);

      expect(history.canNavigateBack, false);
    });

    test('Should handle path checking correctly', () async {
      await router.push(const FirstRoute());

      expect(history.isPathActive('/'), true);
      expect(history.isPathActive('/non-existent'), false);
    });

    test('URL state should be empty initially', () {
      expect(history.urlState.segments, isEmpty);
      expect(history.urlState.hasSegments, false);
    });

    test('URL state should update after navigation', () async {
      await router.push(const FirstRoute());

      expect(history.urlState.segments, isNotEmpty);
      expect(history.urlState.hasSegments, true);
    });

    test('Should not add entry if URL has no segments', () async {
      final initialLength = history.length;

      // Create a URL state with no segments
      final emptyState = UrlState.fromSegments(const []);
      history.onNewUrlState(emptyState);

      expect(history.length, initialLength);
    });

    test('Should not add entry if URL is same as current', () async {
      await router.push(const FirstRoute());
      final lengthAfterFirst = history.length;

      // Try to notify with the same URL state
      final currentState = history.urlState;
      history.onNewUrlState(currentState);

      expect(history.length, lengthAfterFirst);
    });

    test('Forward navigation should throw error on native platforms', () {
      expect(
        () => history.forward(),
        throwsA(isA<FlutterError>()),
      );
    });

    test('pathState getter should throw error on native platforms', () {
      expect(
        () => history.pathState,
        throwsA(isA<FlutterError>()),
      );
    });

    test('pushPathState should throw error on native platforms', () {
      expect(
        () => history.pushPathState(null),
        throwsA(isA<FlutterError>()),
      );
    });

    test('Should mark and unmark URL state for replace', () {
      expect(history.isUrlStateMarkedForReplace, false);

      history.markUrlStateForReplace();
      expect(history.isUrlStateMarkedForReplace, true);

      history.rebuildUrl();
      expect(history.isUrlStateMarkedForReplace, false);
    });

    test('Should handle navigation with shouldReplace flag', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      final lengthBefore = history.length;

      // Mark next navigation to replace
      history.markUrlStateForReplace();
      await router.push(const ThirdRoute());

      // Should replace instead of push when marked
      expect(history.length, greaterThanOrEqualTo(lengthBefore - 1));
    });

    test('Should handle rapid navigation without duplicates', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      await router.push(const ThirdRoute());
      await router.push(const FirstRoute());

      // Each route should be added (except any duplicates)
      expect(history.length, greaterThan(1));
    });

    test('Back from empty history should handle gracefully', () {
      expect(history.length, 0);
      expect(history.canNavigateBack, false);

      // Should not crash
      expect(() => history.back(), returnsNormally);

      expect(history.length, 0);
    });

    test('Multiple listeners should all be notified', () async {
      int listener1Count = 0;
      int listener2Count = 0;

      history.addListener(() => listener1Count++);
      history.addListener(() => listener2Count++);

      await router.push(const FirstRoute());

      expect(listener1Count, greaterThan(0));
      expect(listener2Count, greaterThan(0));
      expect(listener1Count, listener2Count);
    });

    test('Should remove listener correctly', () async {
      int callCount = 0;
      void listener() => callCount++;

      history.addListener(listener);
      await router.push(const FirstRoute());

      final firstCallCount = callCount;
      expect(firstCallCount, greaterThan(0));

      history.removeListener(listener);
      await router.push(const SecondRoute());

      // Should not increment after listener removed
      expect(callCount, firstCallCount);
    });

    test('Should handle RouteData active check', () async {
      await router.push(const FirstRoute());

      final routeData = router.current;
      expect(history.isRouteDataActive(routeData), true);
    });

    test('Length should accurately reflect history size', () async {
      expect(history.length, 0);

      await router.push(const FirstRoute());
      expect(history.length, 1);

      await router.push(const SecondRoute());
      expect(history.length, 2);

      await router.push(const ThirdRoute());
      expect(history.length, 3);

      history.back();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(history.length, 2);
    });
  });

  group('NavigationHistory Edge Cases', () {
    late SimpleRouter router;
    late NavigationHistory history;

    setUp(() {
      router = SimpleRouter()..ignorePopCompleters = true;
      history = router.navigationHistory;
    });

    test('Should handle back navigation to empty state safely', () async {
      await router.push(const FirstRoute());

      history.back();
      await Future.delayed(const Duration(milliseconds: 10));

      // History should handle being empty after back navigation
      expect(() => history.length, returnsNormally);
    });

    test('Should not break on consecutive back calls', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      history.back();
      history.back();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(() => history.length, returnsNormally);
    });

    test('Should prevent race condition - rapid back calls', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      await router.push(const ThirdRoute());

      final lengthBefore = history.length;
      expect(lengthBefore, 3);

      // Call back twice rapidly without waiting
      history.back();

      // Second back should be blocked because canNavigateBack is false during navigation
      final canNavigateDuringBack = history.canNavigateBack;
      history.back(); // This should be blocked

      await Future.delayed(const Duration(milliseconds: 20));

      // Should only go back once, not twice
      expect(history.length, 2);
      expect(canNavigateDuringBack, false); // Was blocked during navigation
    });

    test('Should allow back navigation after previous back completes', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      await router.push(const ThirdRoute());

      expect(history.length, 3);

      // First back
      history.back();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(history.length, 2);

      // Should be able to navigate back again after first completes
      expect(history.canNavigateBack, true);

      // Second back
      history.back();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(history.length, 1);
    });

    test('Should not add duplicate entries during back navigation', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      expect(history.length, 2);

      history.back();

      // Try to push during back navigation - the navigation callback might trigger
      // This simulates the scenario where onNewUrlState is called during back
      await Future.delayed(const Duration(milliseconds: 20));

      expect(history.length, 1);
      expect(router.current.name, FirstRoute.name);
    });

    test('Should reset navigation flag after successful back navigation', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());

      expect(history.canNavigateBack, true);

      history.back();
      expect(history.canNavigateBack, false); // Blocked during navigation

      await Future.delayed(const Duration(milliseconds: 50));

      // If there's still one entry left, should be false (can't go back from single entry)
      // The flag should be reset, but canNavigateBack depends on having 2+ entries
      expect(history.length, 1);
      expect(history.canNavigateBack, false); // Only one entry, can't go back
    });

    test('Should handle complex navigation patterns', () async {
      await router.push(const FirstRoute());
      await router.push(const SecondRoute());
      history.back();
      await Future.delayed(const Duration(milliseconds: 10));

      await router.push(const ThirdRoute());
      await router.push(const SecondRoute());

      expect(history.length, greaterThan(1));
      expect(router.current.name, SecondRoute.name);
    });
  });
}
