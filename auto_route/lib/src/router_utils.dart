import 'package:flutter/material.dart';

// returns an error page routes with a helper message.
PageRoute unknownRoutePage(String routeName) => MaterialPageRoute(
      builder: (ctx) => Scaffold(
        body: Container(
          color: Colors.redAccent,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text(
                  routeName == "/"
                      ? 'Initial route not found! \n did you forget to annotate your home page with @initial or @MaterialRoute(initial:true)?'
                      : 'Route name $routeName is not found!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              OutlineButton.icon(
                label: Text('Back'),
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(ctx).pop(),
              )
            ],
          ),
        ),
      ),
    );

// checks whether the passed args are valid
// if isRequired is true the passed args can not be null.
bool hasInvalidArgs<T>(Object args, {bool isRequired = false}) {
  if (isRequired) {
    return (args is! T);
  } else {
    return (args != null && args is! T);
  }
}

PageRoute misTypedArgsRoute<T>(Object args) {
  return MaterialPageRoute(
    builder: (ctx) => Scaffold(
      body: Container(
        color: Colors.redAccent,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Arguments Mistype!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Expected (${T.toString()}),  found (${args.runtimeType})',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            OutlineButton.icon(
              label: Text('Back'),
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(ctx).pop(),
            )
          ],
        ),
      ),
    ),
  );
}
