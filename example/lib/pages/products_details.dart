import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class ProductDetails extends StatelessWidget {
  final int id;
  final String name;

  const ProductDetails(this.id, {this.name = "default name"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(name)),
      ),
    );
  }
}
