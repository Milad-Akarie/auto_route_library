import 'package:flutter/material.dart';

class PageOneScreen extends StatefulWidget {
  const PageOneScreen({Key? key}) : super(key: key);
  @override
  State<PageOneScreen> createState() => _PageOneScreenState();
}

class _PageOneScreenState extends State<PageOneScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Page 1'),
    );
  }
}
