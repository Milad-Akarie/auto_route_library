import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A PopScope on a step of a nested onboarding flow takes back.
// https://github.com/Milad-Akarie/auto_route_library/issues/1957
// Headless test: auto_route/test/nested_router/pop_scope_step_test.dart
//
// Setup: an onboarding host page with an app bar and an AutoRouter showing
// one step at a time. The ID step shows a choice of ID type, then a number
// form wrapped in PopScope(canPop: false), which takes back and returns to
// the choice.
// Steps: push the host, push the ID step, choose a type, then go back twice.
// Reported: back ignored the step's PopScope and left the step.
// Should: the first back shows the choice again; the second goes back to
// the first step, inside the host.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    _popAttempts = 0;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(
          page: _OnboardingRoute.page,
          path: '/onboarding',
          children: [
            AutoRoute(page: _WelcomeStepRoute.page, path: ''),
            AutoRoute(page: _IdStepRoute.page, path: 'id'),
          ],
        ),
      ],
    );
  });

  Future<void> openIdNumberForm(WidgetTester tester, {ThemeData? theme}) async {
    await pumpRouterApp(tester, router, theme: theme);
    unawaited(router.push(const _OnboardingRoute()));
    await tester.pumpAndSettle();
    unawaited(
      router
          .innerRouterOf<StackRouter>(_OnboardingRoute.name)!
          .push(const _IdStepRoute()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_chooseType));
    await tester.pumpAndSettle();
    expect(find.text(_numberForm), findsOneWidget);
  }

  void expectOnIdStep({required bool showingForm}) {
    expect(router.current.name, _OnboardingRoute.name);
    expect(router.topRoute.name, _IdStepRoute.name);
    expect(find.text(_numberForm), showingForm ? findsOneWidget : findsNothing);
    expect(find.text(_chooseType), showingForm ? findsNothing : findsOneWidget);
  }

  void expectOnWelcomeStep() {
    expect(router.current.name, _OnboardingRoute.name);
    expectTopPage(router, _WelcomeStepRoute.name);
  }

  Future<void> tapAppBarBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  final backs = <String, Future<void> Function(WidgetTester)>{
    'system back': systemBack,
    'the app bar back button': tapAppBarBack,
  };

  for (final MapEntry(key: name, value: back) in backs.entries) {
    testWidgets(
      '$name on a step with a PopScope stays on the step, then leaves it',
      (tester) async {
        await openIdNumberForm(tester);

        await back(tester);
        expectOnIdStep(showingForm: false);
        expect(_popAttempts, 1);

        await back(tester);
        expectOnWelcomeStep();
        expect(_popAttempts, 1);
      },
    );
  }

  // The swipe doesn't start while a PopScope blocks the page, as in a flat
  // route. Run with the iOS page transitions on every platform.
  testWidgets(
    'the iOS back swipe on a step with a PopScope stays on the step',
    (tester) async {
      await openIdNumberForm(tester, theme: ThemeData(platform: .iOS));

      await swipeBack(tester);
      expectOnIdStep(showingForm: true);

      await tester.tap(find.text(_backToChoice));
      await tester.pumpAndSettle();
      await swipeBack(tester);
      expectOnWelcomeStep();
    },
  );
}

const _chooseType = 'Choose national ID';
const _numberForm = 'National ID number';
const _backToChoice = 'Change ID type';
var _popAttempts = 0;

class _OnboardingRoute extends PageRouteInfo<void> {
  const _OnboardingRoute() : super(name);

  static const String name = 'OnboardingRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: const AutoRouter(),
    ),
  );
}

class _WelcomeStepRoute extends PageRouteInfo<void> {
  const _WelcomeStepRoute() : super(name);

  static const String name = 'WelcomeStepRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _IdStepRoute extends PageRouteInfo<void> {
  const _IdStepRoute() : super(name);

  static const String name = 'IdStepRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _IdStep());
}

class _IdStep extends StatefulWidget {
  const _IdStep();

  @override
  State<_IdStep> createState() => _IdStepState();
}

class _IdStepState extends State<_IdStep> {
  var _showingForm = false;

  @override
  Widget build(BuildContext context) {
    if (!_showingForm) {
      return TextButton(
        onPressed: () => setState(() => _showingForm = true),
        child: const Text(_chooseType),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popAttempts++;
        setState(() => _showingForm = false);
      },
      child: Column(
        children: [
          const Text(_numberForm),
          TextButton(
            onPressed: () => setState(() => _showingForm = false),
            child: const Text(_backToChoice),
          ),
        ],
      ),
    );
  }
}
