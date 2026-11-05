import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../no_op.dart';

// The same scenario as flutter/flutter#117342 in go_router: under
// WidgetsApp.router, a tap on an empty part of a page beeped on macOS. The
// tap fell through the page to the modal barrier beneath it, which plays the
// alert sound, because go_router built its pages with no transition there.
//
// auto_route's default route type is material, which on macOS uses the
// Cupertino transition: its decorated box takes the tap, so nothing beeps.
// Every route type plays the sound exactly when Flutter's own page of that
// kind does: a page whose content doesn't take the tap beeps on every
// platform, in Flutter as in auto_route. So the beep of a custom route type,
// or of the material one on Linux and Windows, is Flutter's behavior, not
// auto_route's; nothing to fix.
void main() {
  const content = Center(child: Text('Home Page'));
  Page<void> flutterMaterial() => const MaterialPage(child: content);
  Page<void> flutterCupertino() => const CupertinoPage(child: content);
  Page<void> flutterBuilder() => const _PageRouteBuilderPage(content);

  final types = <String, (RouteType?, Page<void> Function())>{
    'the default route type': (null, flutterMaterial),
    'the material route type': (const RouteType.material(), flutterMaterial),
    'the cupertino route type': (const RouteType.cupertino(), flutterCupertino),
    // On web the adaptive route type builds a route with no transition.
    'the adaptive route type': (
      const RouteType.adaptive(),
      () => kIsWeb
          ? flutterBuilder()
          : defaultTargetPlatform == .macOS
          ? flutterCupertino()
          : flutterMaterial(),
    ),
    'a custom route type': (RouteType.custom(), flutterBuilder),
    'a custom route type with no transition': (
      RouteType.custom(transitionsBuilder: TransitionsBuilders.noTransition),
      flutterBuilder,
    ),
  };

  for (final MapEntry(key: name, value: (type, flutterPage)) in types.entries) {
    // Steps: WidgetsApp.router opens a page built as Center(child: Text)
    // with the route type; tap the page below the text. Then do the same
    // with Flutter's own page of that kind in a plain Navigator.
    // Should: auto_route plays the alert sound exactly when Flutter does.
    testWidgets('a tap on a page of $name sounds as on the same Flutter page', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => content),
            type: type,
          ),
        ],
      );
      addTearDown(router.dispose);
      final autoRouteSounds = await _soundsOfTap(
        tester,
        WidgetsApp.router(color: const Color(0xFFFFFFFF), routerConfig: router.config()),
      );
      final flutterSounds = await _soundsOfTap(
        tester,
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          builder: (_, _) => Navigator(pages: [flutterPage()], onDidRemovePage: ignoreArgument),
        ),
      );
      expect(autoRouteSounds, flutterSounds);
    }, variant: TargetPlatformVariant.desktop());
  }

  // The reported setup: the default route type, on macOS.
  testWidgets('a tap on a page of the default route type under WidgetsApp.router plays no sound on macOS', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => content),
        ),
      ],
    );
    addTearDown(router.dispose);
    final sounds = await _soundsOfTap(
      tester,
      WidgetsApp.router(color: const Color(0xFFFFFFFF), routerConfig: router.config()),
    );
    expect(sounds, isEmpty);
  }, variant: TargetPlatformVariant.only(.macOS));
}

/// Shows [app], taps it below its text, and returns the sounds played.
Future<List<Object?>> _soundsOfTap(WidgetTester tester, Widget app) async {
  final sounds = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemSound.play') sounds.add(call.arguments);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  expect(find.text('Home Page'), findsOneWidget);
  await tester.tapAt(const Offset(400, 500));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  // A new app next: drop this one, so the next pumpWidget builds afresh.
  await tester.pumpWidget(const SizedBox());
  return sounds;
}

class _PageRouteBuilderPage extends Page<void> {
  const _PageRouteBuilderPage(this.child);

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) =>
      PageRouteBuilder<void>(settings: this, pageBuilder: (_, _, _) => child);
}
