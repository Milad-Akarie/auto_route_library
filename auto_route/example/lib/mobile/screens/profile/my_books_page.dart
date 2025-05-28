import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage()
class MyBooksPage extends StatelessWidget {
  final String? filter;

  const MyBooksPage({super.key, @queryParam this.filter = 'none2'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'My Books -> filter: $filter',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Fragment Support? ${context.routeData.fragment}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.navigateTo(
                  SettingsTab(tab: 'newSegment', query: 'newQuery'),
                );
              },
              child: Text('navigate to /settings/newSegment'),
            ),
            ElevatedButton(
              onPressed: () => context.back(),
              child: Text('Navigate back'),
            ),
            ElevatedButton(
              onPressed: () => context.router.root.pushAndPopUntil(HomeRoute(), predicate: (_) => false),
              child: Text('Pop until /home'),
            ),
          ],
        ),
      ),
    );
  }
}
