import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/127803:
// iPad Scribble asserts "RenderBox was not laid out" on a covered page.
// Setup: a page with a TextField under a second page, both shown at once, so
// the first is built but never laid out. Plain Flutter with a Navigator given
// both pages, and an auto_route app opened on the deep link /top.
// Steps: send the message iOS sends when a pencil touches the screen, a
// request for the text fields in a rect, over the whole screen.
// Today every text field registers for Scribble while it is mounted, and
// TextInput asks each one for its bounds (services/text_input.dart, the
// requestElementsInRect case), which reads the size of a box never laid out
// (widgets/editable_text.dart, the bounds getter of _ScribbleFocusableState).
// A page covered after it was shown answers; one covered from the start
// throws.
// LongCatIsLooong (Flutter): Scribble should skip fields that can't be used.
// If this test fails after a Flutter upgrade, Scribble no longer measures a
// page that was never laid out: drop this canary.
void main() {
  Future<String?> requestElements(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        const MethodCall('TextInputClient.requestElementsInRect', [
          0.0,
          0.0,
          800.0,
          600.0,
        ]),
      ),
      null,
    );

    return tester.takeException()?.toString();
  }

  testWidgets('a covered plain page fails Scribble', (tester) async {
    final pages = [
      const MaterialPage<void>(
        key: ValueKey('field'),
        child: Material(child: TextField()),
      ),
      const MaterialPage<void>(key: ValueKey('top'), child: Text('Top')),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(pages: pages, onDidRemovePage: pages.remove),
      ),
    );

    expect(
      await requestElements(tester),
      contains('RenderBox was not laid out'),
    );
  });

  testWidgets('a covered auto_route page fails Scribble', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'FieldRoute',
            builder: (_) => const Material(child: TextField()),
          ),
        ),
        AutoRoute(
          path: '/top',
          page: PageInfo('TopRoute', builder: (_) => const Text('Top')),
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/top');

    expect(router.stack.map((page) => page.name), ['FieldRoute', 'TopRoute']);
    expect(
      await requestElements(tester),
      contains('RenderBox was not laid out'),
    );
  });
}
