import 'package:flutter/material.dart';

class PageTwoScreen extends StatefulWidget {
  const PageTwoScreen({Key? key}) : super(key: key);
  @override
  State<PageTwoScreen> createState() => _PageTwoScreenState();
}

class _PageTwoScreenState extends State<PageTwoScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Page 2'),
    );
  }
}
