//import 'dart:ui' as ui;

import 'package:example/model.dart';
import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
//  final ui.Image image;
  final Model model;

  const TestPage({this.model
//    this.image,
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Test page"),
      ),
    );
  }
}
