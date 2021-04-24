import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class MyBooksPage extends StatelessWidget {
  final String filter;

  const MyBooksPage({Key? key, @queryParam this.filter = 'none'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'My Books -> filter: $filter',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Text(
              'Fragment Support? ${context.routeData.fragment}',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.router.navigateNamed('settings');
                //   return context.router.navigate(
                //   BooksTab(),
                // );
              },
              child: Text('Go Back'),
            )
          ],
        ),
      ),
    );
  }
}
