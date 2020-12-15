import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/router.gr.dart';
import 'package:flutter/material.dart';

import '../web_main.dart';

class BookListPage extends StatefulWidget {
  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('+++++ Initiating list state $hashCode');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: booksDb.books
                  .map((book) => Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(book.name),
                          subtitle: Text(book.genre),
                          onTap: () {
                            context.findChildRouter(BookListPageRoute.key).push(BookDetailsPageRoute(id: book.id));
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: AutoRouter(),
          )
        ],
      ),
    );
  }
}
