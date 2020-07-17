import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// returns an error page routes with a helper message.
PageRoute defaultUnknownRoutePage(RouteSettings settings) => MaterialPageRoute(
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
                  'Route name ${settings.name} is not found!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              if (!ModalRoute.of(ctx).isFirst)
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

PageRoute<T> buildAdaptivePageRoute<T>({
  @required WidgetBuilder builder,
  RouteSettings settings,
  bool maintainState = true,
  bool fullscreenDialog = false,
  String cupertinoTitle,
}) {
  assert(builder != null);
  assert(maintainState != null);
  assert(fullscreenDialog != null);
  // no transitions for web
  if (kIsWeb) {
    return PageRouteBuilder(
      pageBuilder: (ctx, _, __) => builder(ctx),
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  } else if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      title: cupertinoTitle,
    );
  } else {
    return MaterialPageRoute<T>(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
}
