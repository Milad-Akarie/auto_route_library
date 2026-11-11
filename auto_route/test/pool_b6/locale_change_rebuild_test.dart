import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/666
// Setup, as in the report: MaterialApp.router with routerDelegate and
// routeInformationParser of an AutoRoute router, and `locale:` taken from
// state above it (the report uses easy_localization's context.locale).
// The locales differ by country only (en_US, en_GB, en_AU), so the default
// localization delegates support all of them.
// Steps: show a page that reads Localizations.localeOf, change the locale
// above the app once; then push a second page and change it again.
// Reported: the page doesn't rebuild at the first change, only at the next
// one, and then with the previous language.
// Should: the page on top shows the new locale at once after each change.
void main() {
  late ValueNotifier<Locale> locale;
  late RootStackRouter router;

  setUp(() {
    locale = ValueNotifier(const Locale('en', 'US'));
    addTearDown(locale.dispose);
    router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (context, _) =>
              Scaffold(body: Text('Home ${Localizations.localeOf(context)}')),
        ),
        NamedRouteDef(
          name: 'DetailsRoute',
          path: '/details',
          builder: (context, _) => Scaffold(
            body: Text('Details ${Localizations.localeOf(context)}'),
          ),
        ),
      ],
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp.router(
          routeInformationParser: router.defaultRouteParser(
            includePrefixMatches: true,
          ),
          routerDelegate: router.delegate(),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('en', 'GB'),
            Locale('en', 'AU'),
          ],
          locale: value,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Changing the locale above the app rebuilds the page at once', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Home en_US'), findsOneWidget);

    locale.value = const Locale('en', 'GB');
    await tester.pumpAndSettle();
    expect(
      find.text('Home en_GB'),
      findsOneWidget,
      reason: "after locale.value = const Locale('en', 'GB')",
    );

    locale.value = const Locale('en', 'AU');
    await tester.pumpAndSettle();
    expect(
      find.text('Home en_AU'),
      findsOneWidget,
      reason: "after locale.value = const Locale('en', 'AU')",
    );
  });

  testWidgets('Changing the locale rebuilds the pushed page and the one under '
      'it', (tester) async {
    await pumpApp(tester);
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Details en_US'), findsOneWidget);

    locale.value = const Locale('en', 'GB');
    await tester.pumpAndSettle();

    expect(
      find.text('Details en_GB'),
      findsOneWidget,
      reason: "after locale.value = const Locale('en', 'GB')",
    );
    expect(
      find.text('Home en_GB', skipOffstage: false),
      findsOneWidget,
      reason: "after locale.value = const Locale('en', 'GB')",
    );
  });
}
