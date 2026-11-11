import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/picker_router.dart';

// A screen opened with a result type and reached again by a link closes
// without a type error.
// Headless test: auto_route/test/simple_router/typed_screen_reached_again_test.dart
// Flutter's Navigator keeps the route of a page that a page of the same type
// and key replaces, and its Page.canUpdate compares types, type arguments
// included, so a route only ever shows a page it can cast to its own result
// type when it closes.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('typed screen reached again', () {
    // Steps: push PickerRoute<int> with push<int>, send a link to /picker from
    // the platform, as a deep link to the running app does, then go back the
    // way the platform does.
    // Happened: since 12.5.0, back threw "type 'AutoRoutePage<Object?>' is
    // not a subtype of type 'Page<int>'", and the picker stayed.
    // Should: the link shows its title on the picker, and back closes it.
    testWidgets(
      'Back closes a screen opened with push<int> and reached again by a link',
      (tester) async {
        final router = PickerRouter();
        await pumpRouterAppWithConfig(tester, router);
        router.push<int>(PickerRoute<int>(items: const [1, 2, 3])).ignore();
        await tester.pumpAndSettle();
        expect(find.text('Pick from 3'), findsOneWidget);

        await _openLink(tester, '/picker?title=Again');
        expect(find.text('Again from 0'), findsOneWidget);
        await expectBrowserUrl('/picker?title=Again');

        await systemBack(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        await expectBrowserUrl('/');
      },
    );
  });
}

// Sends [location] to the app on the navigation channel, as the engine does
// for a link the platform opens in the running app, and waits for its page.
Future<void> _openLink(WidgetTester tester, String location) async {
  const codec = JSONMethodCodec();
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    codec.encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': location, 'state': null}),
    ),
    null,
  );
  await tester.pumpAndSettle();
}
