import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
class SingleFieldPage extends StatefulWidget {
  final String message;
  final String willPopMessage;
  final void Function(String)? onNext;

  const SingleFieldPage({
    super.key,
    this.message = '',
    this.willPopMessage = '',
    this.onNext,
  });

  @override
  SingleFieldPageState createState() => SingleFieldPageState();
}

class SingleFieldPageState extends State<SingleFieldPage> {
  String _text = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.willPopMessage)),
        );
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
                child: Text('Next'))
          ],
        ),
      ),
    );
  }
}
