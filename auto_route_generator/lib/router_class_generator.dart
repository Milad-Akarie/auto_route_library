import 'package:auto_route_generator/route_config_visitor.dart';

class RouterClassGenerator {
  final List<RouteConfig> routes;

  final StringBuffer _stringBuffer = StringBuffer();
  final String className;

  RouterClassGenerator(this.className, this.routes);

  // helper functions
  void _write(Object obj) => _stringBuffer.write(obj);

  void _writeln([Object obj]) => _stringBuffer.writeln(obj);

  void _newLine() => _stringBuffer.writeln();

  String generate() {
    _generateImports();
    _generateRouterClass();
    _generateArgumentHolders();
    return _stringBuffer.toString();
  }

  void _generateImports() {
    // write route imports
    final Set<String> imports = {
      "'package:flutter/material.dart'",
      "'package:flutter/cupertino.dart'",
      "'package:auto_route/router_utils.dart'"
    };
    routes.forEach((r) {
      imports.add(r.import);
      if (r.transitionBuilder != null) imports.add(r.transitionBuilder.import);
      if (r.parameters != null) {
        r.parameters.forEach((param) {
          if (param.imports != null) imports.addAll(param.imports);
        });
      }
    });
    imports.where((import) => import != null).forEach((import) => _writeln('import $import;'));
  }

  void _generateRouteNames(List<RouteConfig> routes) {
    _newLine();
    routes.forEach((r) {
      final routeName = r.name;
      if (r.initial != null && r.initial) {
        _writeln("static const $routeName = '/';");
      } else {
        return _writeln("static const $routeName = '/$routeName';");
      }
    });
  }

  void _generateRouteGeneratorFunction(List<RouteConfig> routes) {
    _newLine();
    _writeln('static Route<dynamic> onGenerateRoute(RouteSettings settings) {');
    _writeln('final args = settings.arguments;');
    _writeln('switch (settings.name) {');

    routes.forEach((r) => generateRoute(r));

    // build unknown route error page if route is not found
    _writeln('default: return unknownRoutePage(settings.name);');
    // close switch case
    _writeln('}');
    _newLine();

    // close onGenerateRoute function
    _writeln('}');
  }

  void generateRoute(RouteConfig r) {
    _writeln('case $className.${r.name}:');

    StringBuffer constructorParams = StringBuffer('');

    if (r.parameters != null && r.parameters.isNotEmpty) {
      if (r.parameters.length == 1) {
        final param = r.parameters[0];

        // show an error page if passed args are not the same as declared args
        _writeln('if(hasInvalidArgs<${param.type}>(args');
        if (param.isRequired) {
          _write(',isRequired:true');
        }
        _write('))');
        _writeln('{return misTypedArgsRoute<${param.type}>(args);}');

        _writeln('final typedArgs = args as ${param.type}');
        if (param.defaultValueCode != null) {
          _write(' ?? ${param.defaultValueCode}');
        }
        _write(';');
        if (param.isPositional) {
          constructorParams.write('typedArgs');
        } else {
          constructorParams.write('${param.name}: typedArgs');
        }
      } else {
        // if router has any required params the argument class holder becomes required.
        final hasRequiredParams = r.parameters
            .where((p) => p.isRequired)
            .isNotEmpty;
        // show an error page  if passed args are not the same as declared args
        _writeln('if(hasInvalidArgs<${r.className}Arguments>(args');
        if (hasRequiredParams) {
          _write(',isRequired:true');
        }
        _write('))');
        _writeln('{return misTypedArgsRoute<${r.className}Arguments>(args);}');

        _writeln('final typedArgs = args as ${r.className}Arguments');
        if (!hasRequiredParams) {
          _write(' ?? ${r.className}Arguments()');
        }
        _write(';');

        r.parameters.asMap().forEach((i, param) {
          if (param.isPositional) {
            constructorParams.write('typedArgs.${param.name}');
          } else {
            constructorParams.write('${param.name}:typedArgs.${param.name}');
          }
          if (i != r.parameters.length - 1) {
            constructorParams.write(',');
          }
        });
      }
    }

    final widget = "${r.className}(${constructorParams.toString()})${r.hasWrapper ? ".wrappedRoute" : ""}";

    if (r.routeType == RouteType.cupertino) {
      _write('return CupertinoPageRoute(builder: (_) => $widget, settings: settings,');
      if (r.cupertinoNavTitle != null) {
        _write("title:'${r.cupertinoNavTitle}',");
      }
    } else if (r.routeType == RouteType.material) {
      _write('return MaterialPageRoute(builder: (_) => $widget, settings: settings,');
    } else {
      _write(
          'return PageRouteBuilder(pageBuilder: (ctx, animation, secondaryAnimation) => $widget, settings: settings,');
    }

    // generated shared props
    if (r.fullscreenDialog != null) {
      _write('fullscreenDialog:${r.fullscreenDialog.toString()},');
    }
    if (r.maintainState != null) {
      _write('maintainState:${r.maintainState.toString()},');
    }

    if (r.routeType != RouteType.custom) {
      if (r.customRouteOpaque != null) {
        _write('opaque:${r.customRouteOpaque.toString()},');
      }
      if (r.customRouteBarrierDismissible != null) {
        _write('barrierDismissible:${r.customRouteBarrierDismissible.toString()},');
      }
      if (r.transitionBuilder != null) {
        _write('transitionsBuilder: ${r.transitionBuilder.name},');
      }
      if (r.durationInMilliseconds != null) {
        _write('transitionDuration: Duration(milliseconds: ${r.durationInMilliseconds}),');
      }
    }
    _writeln(');');
  }

  void _generateArgumentHolders() {
    final routesWithArgsHolders = Map<String, RouteConfig>();

    // make sure we only generated holder classes for
    // routes with 2+ parameters
    // also prevent duplicate class with the same name from being generated;
    routes.forEach((r) {
      if (r.parameters != null && r.parameters.length > 1) {
        routesWithArgsHolders[r.className] = r;
      }
    });

    if (routesWithArgsHolders.isNotEmpty) {
      _generateBoxed('Arguments holder classes');
      routesWithArgsHolders.values.forEach((r) {
        _generateArgsHolder(r);
      });
    }
  }

  void _generateArgsHolder(RouteConfig r) {
    _writeln('//${r.className} arguments holder class');
    final argsClassName = '${r.className}Arguments';

    // generate fields
    _writeln('class $argsClassName{');
    r.parameters.forEach((param) {
      _writeln('final ${param.type} ${param.name};');
    });

    // generate constructor
    _writeln('$argsClassName({');
    r.parameters.asMap().forEach((i, param) {
      if (param.isRequired) {
        _write('@required ');
      }
      _write('this.${param.name}');
      if (param.defaultValueCode != null) _write(' = ${param.defaultValueCode}');
      if (i != r.parameters.length - 1) _write(',');
    });
    _writeln('});');

    _writeln('}');
  }

  void _generateBoxed(String message) {
    _writeln('\n//'.padRight(77, '*'));
    _writeln('// $message');
    _writeln('//'.padRight(77, '*'));
    _newLine();
  }

  void _generateRouterClass() {
    _writeln('\nclass $className {');
    _generateRouteNames(routes);
    _generateHelperFunctions();
    _generateRouteGeneratorFunction(routes);

    // close router class
    _writeln('}');
  }

  void _generateHelperFunctions() {
    _writeln('static GlobalKey<NavigatorState> get navigatorKey => getNavigatorKey<$className>();');
    _writeln('static NavigatorState get navigator => navigatorKey.currentState;');
  }
}
