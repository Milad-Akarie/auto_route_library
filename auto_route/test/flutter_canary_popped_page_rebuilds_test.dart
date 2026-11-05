import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/116994.
// Setup, without auto_route: a Navigator built from a pages list, as
// auto_route's routers build theirs, and a page whose state subscribes to a
// RouteObserver with ModalRoute.of(context).
// Steps: show the page, then pop it.
// Today the popped page runs didChangeDependencies and build once more,
// after didPop and before dispose. Removing the page rebuilds the Navigator,
// which tells every route its external state changed, so the popped route
// rebuilds its scope and the page's ModalRoute dependency fires. A Navigator
// popped with Navigator.pop and no pages list does not do it. auto_route
// hands its Navigator a pages list, so every page that reads ModalRoute.of,
// as RouteObserver subscribers do, gets the extra build; AutoRouteAware
// subscribers do not, since they read no ModalRoute.
// If this test fails after a Flutter upgrade, Flutter no longer rebuilds a
// popped page: drop this canary.
void main() {
  testWidgets('a page popped from Navigator.pages builds once more after didPop', (tester) async {
    final events = <String>[];
    final observer = RouteObserver<ModalRoute<void>>();
    final pages = <Page<void>>[
      const MaterialPage(key: ValueKey('home'), child: Text('home')),
      MaterialPage(key: const ValueKey('aware'), child: _AwarePage(observer, events)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Navigator(
            observers: [observer],
            pages: List.of(pages),
            onDidRemovePage: (page) => setState(() => pages.remove(page)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(events, ['didChangeDependencies', 'didPush', 'build']);

    events.clear();
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    expect(events, ['didPop', 'didChangeDependencies', 'build', 'dispose']);
  });

  testWidgets('control: a page popped with Navigator.pop and no pages list does not build again', (tester) async {
    final events = <String>[];
    final observer = RouteObserver<ModalRoute<void>>();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, navigatorObservers: [observer], home: const Text('home')),
    );
    navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => _AwarePage(observer, events)));
    await tester.pumpAndSettle();

    events.clear();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(events, ['didPop', 'dispose']);
  });
}

class _AwarePage extends StatefulWidget {
  const new(this.observer, this.events);

  final RouteObserver<ModalRoute<void>> observer;
  final List<String> events;

  @override
  State<_AwarePage> createState() => _AwarePageState();
}

class _AwarePageState extends State<_AwarePage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.events.add('didChangeDependencies');
    widget.observer.subscribe(this, ModalRoute.of(context)! as ModalRoute<void>);
  }

  @override
  void didPush() => widget.events.add('didPush');

  @override
  void didPop() => widget.events.add('didPop');

  @override
  void dispose() {
    widget.events.add('dispose');
    widget.observer.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    return const Text('aware');
  }
}
