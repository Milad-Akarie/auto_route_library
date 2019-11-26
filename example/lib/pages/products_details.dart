import 'package:auto_route/auto_route_annotation.dart';
import 'package:example/pages/custom_paramater.dart';
import 'package:flutter/material.dart';

@AutoRoute(fullscreenDialog: false)
class ProductDetails extends StatelessWidget {
  final CustomParam param;
  final String name;
  const ProductDetails(this.param, this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(param.toString())),
      ),
    );
  }
}
