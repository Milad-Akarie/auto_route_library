import 'package:auto_route/auto_route_annotation.dart';
import 'package:example/pages/custom_paramater.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class ProductDetailsRefactored extends StatelessWidget {
  final CustomParam param;
  final String name;
  const ProductDetailsRefactored(this.param,this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(param.toString())),
      ),
    );
  }
}
