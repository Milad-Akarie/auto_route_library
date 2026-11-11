import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// The route the picker page was last built in.
Route<Object?>? _pickerRoute;

// A screen that answers a number, and counts taps in its own state.
class _PickerPage extends StatefulWidget {
  const new(this.query);

  final String? query;

  @override
  State<_PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends State<_PickerPage> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    _pickerRoute = ModalRoute.of(context);
    return Column(
      children: [
        Text('picker q=${widget.query ?? '-'} taps $taps'),
        TextButton(
          onPressed: () => setState(() => taps++),
          child: const Text('tap'),
        ),
      ],
    );
  }
}

AutoRoute _page(String name, String path) => .new(
  page: PageInfo(name, builder: (_) => Text(name)),
  path: path,
);

RootStackRouter _buildRouter() => .build(
  routes: [
    _page('HomeRoute', '/'),
    AutoRoute(
      page: PageInfo(
        'PickerRoute',
        builder: (data) => _PickerPage(data.queryParams.optString('q')),
      ),
      path: '/picker',
    ),
    _page('OtherRoute', '/other'),
    _page('LastRoute', '/last'),
  ],
);

const NamedRoute<Object?> _picker = NamedRoute('PickerRoute');
const NamedRoute<Object?> _pickerAgain = NamedRoute(
  'PickerRoute',
  queryParams: {'q': '1'},
);

void main() {
  setUp(() => _pickerRoute = null);

  // Steps: push PickerRoute with an int result type, tap it once, navigate
  // to PickerRoute with a new query param, as a link to it does, then press
  // system back.
  // Happened: since 12.5.0, back threw a type error: the new page, built with
  // the type navigate names, took over the picker's route, which casts its
  // page to the int type it was pushed with.
  // Should: the picker keeps its route and its state through the navigation
  // and back closes it. Flutter's Navigator keeps the route of a page that a
  // page of the same type and key replaces, and its Page.canUpdate compares
  // types, type arguments included, so a route only ever shows a page it can
  // cast to its own result type when it closes.
  testWidgets(
    'Back closes a screen opened with push<int> and reached again by navigate',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.push<int>(_picker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      final route = _pickerRoute;

      unawaited(router.navigate(_pickerAgain));
      await tester.pumpAndSettle();
      expect(find.text('picker q=1 taps 1'), findsOneWidget);
      expect(_pickerRoute, same(route));

      await systemBack(tester);
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['HomeRoute']);
    },
  );

  // Steps: push PickerRoute with push<int>, navigate to it with a new query
  // param, then close it with 7.
  // Happened: since 12.5.0, the pop threw the same type error.
  // Should: the picker closes, and the navigation that reached it gets 7.
  testWidgets(
    'A screen opened with push<int> and reached again closes with its result',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.push<int>(_picker));
      await tester.pumpAndSettle();
      final navigated = router.navigate(_pickerAgain);
      await tester.pumpAndSettle();

      router.pop(7);
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(await navigated, 7);
    },
  );

  // Steps: push PickerRoute with push<int>, replace it with PickerRoute and a
  // new query param, then close it with 7.
  // Happened: since 12.5.0, the pop threw the same type error.
  // Should: the picker closes, and replace's future gets 7. Its first caller
  // got null when replace took the picker off, as Flutter's pushReplacement
  // completes the route it replaces.
  testWidgets('A screen opened with push<int> and replaced by itself closes', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push<int>(_picker));
    await tester.pumpAndSettle();
    final replaced = router.replace(_pickerAgain);
    await tester.pumpAndSettle();
    expect(find.text('picker q=1 taps 0'), findsOneWidget);

    router.pop(7);
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(await replaced, 7);
  });

  // Steps: push PickerRoute with push<int> and OtherRoute over it, replaceAll
  // with HomeRoute, PickerRoute with a new query param and LastRoute, then
  // close LastRoute and the picker.
  // Happened: since 12.5.0, closing the picker threw the same type error.
  // The navigator gave the picker's Route<int> to the new picker page, built
  // with replaceAll's type, though their keys differ.
  // Should: both close. The new picker page gets a route of its own, as
  // Flutter's Page.canUpdate gives a page of another type.
  testWidgets('A screen opened with push<int> and kept by replaceAll closes', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push<int>(_picker));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('OtherRoute')));
    await tester.pumpAndSettle();
    unawaited(
      router.replaceAll([
        const NamedRoute('HomeRoute'),
        _pickerAgain,
        const NamedRoute('LastRoute'),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('LastRoute'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('picker q=1 taps 0'), findsOneWidget);
    router.pop(7);
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
  });
}
