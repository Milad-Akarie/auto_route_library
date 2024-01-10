import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

class QueryPage extends StatelessWidget {
  const QueryPage({
    Key? key,
    @pathParam this.id = '-',
  }) : super(key: key);
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Query: $id'),
      ),
    );
  }
}