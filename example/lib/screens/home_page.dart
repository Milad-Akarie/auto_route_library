import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Books App')),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              RaisedButton(
                child: Text('Navigate to Batman Book'),
                onPressed: () {
                  context.router.pushPath('/books', preserveFullBackStack: false, onFailure: (failure) {
                    print(failure);
                  });
                  // context.router.pushAll([
                  //   BookListPageRoute(),
                  //   BookDetails(id: 4),
                  // ]);
                },
              )
            ],
          ),
        ));
  }
}
