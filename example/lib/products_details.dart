import 'package:auto_route/route_gen_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class ProductDetails extends StatelessWidget {
  final int id;
  final int name;

  const ProductDetails(this.id, this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Text(id.toString())),
    );
  }
}
