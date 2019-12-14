import 'package:flutter/material.dart';

class NestedSecondPage extends StatelessWidget {
  final String name;
  final int id;
  final double price;

  const NestedSecondPage({this.name, this.id, this.price});

  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text("Nested Page")));
  }
}
