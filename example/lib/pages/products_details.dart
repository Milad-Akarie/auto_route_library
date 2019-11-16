import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../transitions.dart';

@AutoRoute(transitionBuilder: rotationTransition, durationInMilliseconds: 800)
class ProductDetails extends StatelessWidget {
  final String name;
  final int id;

  const ProductDetails({this.id, this.name = "default value"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(name)),
      ),
    );
  }
}
