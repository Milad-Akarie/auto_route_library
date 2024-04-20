import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage(name: 'SettingsTab')
class SettingsPage extends StatefulWidget {
  final String tab;
  final String query;

  SettingsPage({
    Key? key,
    @pathParam this.tab = 'none',
    @queryParam this.query = 'none',
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutoRouteAwareStateMixin<SettingsPage> {
  var queryUpdateCont = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.tab),
            Text(widget.query),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  queryUpdateCont++;
                });
                context.navigateTo(SettingsTab(
                  tab: 'Updated Path param $queryUpdateCont',
                  query: 'updated Query $queryUpdateCont',
                ));
              },
              child: Text('Update Query $queryUpdateCont'),
            ),
            ElevatedButton(
                onPressed: () {
                  context.navigateTo(BooksTab(
                    children: [BookDetailsRoute(id: 2)],
                  ));
                },
                child: Text('Navigate to book details/1'))
          ],
        ),
      ),
    );
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    print('init tab route from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    print('did change tab route from ${previousRoute.name}');
  }
}
