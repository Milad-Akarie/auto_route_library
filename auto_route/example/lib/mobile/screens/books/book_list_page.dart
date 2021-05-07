import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../data/db.dart';
import '../../router/router.gr.dart';

class BookListPage extends StatefulWidget {
  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> with AutoRouteAware {
  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return ListView(
      children: booksDb?.books
              .map((book) => Column(
                    children: [
                      Hero(
                        tag: 'Hero${book.id}',
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(book.name),
                            subtitle: Text(book.genre),
                            onTap: () {
                              BookDetailsRoute(id: book.id).show(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ))
              .toList() ??
          const [],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = RouterScope.of(context).firstObserverOfType<AutoRouteObserver>();
    if (observer != null) {
      observer.subscribe(this, context.routeData);
    }
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    print('Route aware did init tab ----->');
  }

  @override
  void didPopNext() {
    print('Route aware did pop next ----->');
  }

  @override
  void didPushNext() {
    print('Route aware did push next ----->');
  }

  @override
  void didPush() {
    print('books list did push ------>');
  }

  @override
  void didPop() {
    print('books list did pop');
  }
}
