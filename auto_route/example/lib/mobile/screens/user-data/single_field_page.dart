import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SingleFieldPage extends StatefulWidget {
  final String message;
  final String willPopMessage;
  final void Function(String)? onNext;

  const SingleFieldPage({
    Key? key,
    this.message = '',
    this.willPopMessage = '',
    this.onNext,
  }) : super(key: key);

  @override
  _SingleFieldPageState createState() => _SingleFieldPageState();
}

class _SingleFieldPageState extends State<SingleFieldPage> {
  String _text = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(widget.willPopMessage)),
          );
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: [
            const SizedBox(height: 100),
            Text(widget.message),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: TextField(
                decoration: InputDecoration(border: OutlineInputBorder()),
                onChanged: (t) {
                  setState(() {
                    _text = t;
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: _text.isEmpty
                  ? null
                  : () {
                      widget.onNext?.call(_text);
                    },
              child: Text('Next'),
            )
          ],
        ),
      ),
    );
  }
}
