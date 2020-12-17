import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Books App')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                child: Text('Navigate to Book list'),
                onPressed: () {
                  AutoRouter.of(context).push(BookListPageRoute());
                  // or
                  // context.router.push
                },
              ),
              SizedBox(height: 16),
              RaisedButton(
                child: Text('Navigate to Batman Book'),
                onPressed: () {
                  // push too pages at once
                  context.router.pushAll([
                    BookListPageRoute(),
                    BookDetailsPageRoute(id: 4),
                  ]);

                  // or
                  // context.router.pushPath('/books/4', includePrefixMatches: true);
                },
              )
            ],
          ),
        ));
  }
}
