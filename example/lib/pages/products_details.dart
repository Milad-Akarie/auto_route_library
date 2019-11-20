import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class ProductDetails extends StatelessWidget {
  final String name;
  final int id;

  const ProductDetails({this.id, this.name = "changed value"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(name)),
      ),
    );
  }
}
