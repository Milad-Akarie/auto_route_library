import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../main_router.dart';
import '../router_test_utils.dart';

// Guard for https://github.com/Milad-Akarie/auto_route_library/issues/1957
// Setup, as in the report: an onboarding host page with an app bar and an
// AutoRouter that shows one step at a time. The ID step has two states,
// choosing an ID type, then filling in its number; while the number form
// shows, a PopScope(canPop: false) takes back and returns to the choice.
// Steps: push the host (it shows the first step), push the ID step, choose
// a type, then go back twice.
// Happened (reported on auto_route 8): the step's PopScope was ignored and
// back left the step.
// Should: the first back stays on the ID step and shows the choice again;
// the second goes back to the first step, inside the host.
// Not a router bug on dev; this test documents how PopScope works. The
// reporter guessed that a PopScope registers with the top route, and so
// missed steps pushed after it. Flutter registers a PopScope with the route
// that holds it (ModalRoute.of), here the step's route in the nested
// navigator, by design. The reporter's own fix, a PopScope inside the step
// that blocks back while the form shows, is the setup below, and it holds
// on every way back.
void main() {
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
    addTearDown(router.dispose);
  });

  Future<void> openIdNumberForm(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(MaterialApp.router(theme: theme, routerConfig: router.config()));
    await tester.pumpAndSettle();
    unawaited(router.push(const _OnboardingRoute()));
    await tester.pumpAndSettle();
    unawaited(router.innerRouterOf<StackRouter>(_OnboardingRoute.name)!.push(const _IdStepRoute()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_kChooseType));
    await tester.pumpAndSettle();
    expect(find.text(_kNumberForm), findsOneWidget);
  }

  void expectOnIdStep({required bool showingForm}) {
    expect(router.current.name, _OnboardingRoute.name);
    expect(router.topRoute.name, _IdStepRoute.name);
    expect(find.text(_kNumberForm), showingForm ? findsOneWidget : findsNothing);
    expect(find.text(_kChooseType), showingForm ? findsNothing : findsOneWidget);
  }

  void expectOnWelcomeStep() {
    expect(router.current.name, _OnboardingRoute.name);
    expectTopPage(router, _WelcomeStepRoute.name);
  }

  final backs = <String, (Future<void> Function(WidgetTester), ThemeData?)>{
    'system back': (systemBack, null),
    'the predictive back gesture': (predictiveBack, androidTheme),
    'the app bar back button': (tapLeadingBackButton, null),
  };

  for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
    testWidgets('$name on a step with a PopScope should stay on the step, then leave it', (tester) async {
      await openIdNumberForm(tester, theme: theme);

      await back(tester);
      expectOnIdStep(showingForm: false);
      expect(_popAttempts, 1);

      await back(tester);
      expectOnWelcomeStep();
      expect(_popAttempts, 1);
    });
  }

  // The iOS edge swipe doesn't start while a PopScope blocks the page, as in
  // a flat route, so PopScope doesn't hear of it.
  testWidgets('the iOS back swipe on a step with a PopScope should stay on the step', (tester) async {
    await openIdNumberForm(tester, theme: iosTheme);

    await swipeBack(tester);
    expectOnIdStep(showingForm: true);

    await tester.tap(find.text(_kBackToChoice));
    await tester.pumpAndSettle();
    await swipeBack(tester);
    expectOnWelcomeStep();
  });
}

const _kChooseType = 'Choose national ID';
const _kNumberForm = 'National ID number';
const _kBackToChoice = 'Change ID type';
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
      return TextButton(onPressed: () => setState(() => _showingForm = true), child: const Text(_kChooseType));
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
          const Text(_kNumberForm),
          TextButton(onPressed: () => setState(() => _showingForm = false), child: const Text(_kBackToChoice)),
        ],
      ),
    );
  }
}
