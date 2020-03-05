import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';

class RouterClassGenerator {
  final List<RouteConfig> routes;

  final StringBuffer _stringBuffer = StringBuffer();
  final String className;
  final RouterConfig routerConfig;

  RouterClassGenerator(this.className, this.routes, this.routerConfig);
  // helper functions
  void _write(Object obj) => _stringBuffer.write(obj);

  void _writeln([Object obj]) => _stringBuffer.writeln(obj);

  void _newLine() => _stringBuffer.writeln();

  String generate() {
    _generateImports();
    _generateRoutesClass();
    _generateRouterClass();
    _generateArgumentHolders();
    return _stringBuffer.toString();
  }

  void _generateImports() {
    // write route imports
    final imports = {
      "'package:flutter/material.dart'",
      "'package:flutter/cupertino.dart'",
      "'package:auto_route/auto_route.dart'"
    };
    routes.forEach((r) {
      imports.addAll(r.imports);
      if (r.transitionBuilder != null) {
        imports.add(r.transitionBuilder.import);
      }
      if (r.parameters != null) {
        r.parameters.forEach((param) {
          if (param.imports != null) imports.addAll(param.imports);
        });
      }
      if (r.guards != null) {
        r.guards.forEach((g) {
          imports.add(g.import);
        });
      }
    });
    imports
        .where((import) => import != null)
        .forEach((import) => _writeln('import $import;'));
  }

  void _generateRoutesClass() {
    _writeln('abstract class Routes{');
    routes.where((r) => !r.isUnknownRoute).forEach((r) {
      final routeName = r.name;
      final pathName = r.pathName ?? "/${toKababCase(routeName)}";
      if (r.initial == true) {
        _writeln("static const $routeName = '/';");
      } else {
        return _writeln("static const $routeName = '$pathName';");
      }
    });

    if (routerConfig.generateRouteList) {
      _writeln("static const all = [");
      routes
          .where((r) => !r.isUnknownRoute)
          .forEach((r) => _write('${r.name},'));
      _write("];");
    }
    _writeln('}');
  }

  void _generateRouteGeneratorFunction(List<RouteConfig> routes) {
    _newLine();
    _writeln('@override');
    _writeln('Route<dynamic> onGenerateRoute(RouteSettings settings) {');
    _writeln('final args = settings.arguments;');
    _writeln('switch (settings.name) {');

    routes.where((r) => !r.isUnknownRoute).forEach((r) {
      _writeln('case Routes.${r.name}:');

      _generateRoute(r);
    });

    // build unknown route error page if route is not found
    final unknowRoute =
        routes.firstWhere((r) => r.isUnknownRoute == true, orElse: () => null);
    if (unknowRoute != null) {
      _writeln('default: ');
      _generateRouteBuilder(
          unknowRoute, '${unknowRoute.className}(settings.name)');
    } else {
      _writeln('default: return unknownRoutePage(settings.name);');
    }
    // close switch case
    _writeln('}');
    _newLine();

    // close onGenerateRoute function
    _writeln('}');
  }

  void _generateRoute(RouteConfig r) {
    final constructorParams = StringBuffer('');

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
        final hasRequiredParams =
            r.parameters.where((p) => p.isRequired).isNotEmpty;
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

    final constructor =
        "${r.className}(${constructorParams.toString()})${r.hasWrapper ? ".wrappedRoute" : ""}";

    _generateRouteBuilder(r, constructor);
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
      if (param.defaultValueCode != null) {
        _write(' = ${param.defaultValueCode}');
      }
      if (i != r.parameters.length - 1) {
        _write(',');
      }
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
    _writeln('\nclass $className extends RouterBase {');
    _generateHelperFunctions();
    _generateRouteGeneratorFunction(routes);

    // close router class
    _writeln('}');
  }

  void _generateHelperFunctions() {
    final routesWithGuards =
        routes.where((r) => r.guards != null && r.guards.isNotEmpty);

    if (routesWithGuards.isNotEmpty) {
      _writeln('@override');
      _writeln('Map<String, List<Type>> get guardedRoutes => {');
      routesWithGuards.forEach((r) {
        _write(
            'Routes.${r.name}:${r.guards.map((g) => g.type).toSet().toList()},');
      });
      _write('};');
    }

    // _writeln('static final navigator = ExtendedNavigator(');
    // if (routesWithGuards.isNotEmpty) {
    //   _write('_guardedRoutes');
    // }
    // _write(');');
  }

  void _generateRouteBuilder(RouteConfig r, String constructor) {
    final returnType = r.returnType ?? 'dynamic';
    if (r.routeType == RouteType.cupertino) {
      _write(
          'return CupertinoPageRoute<$returnType>(builder: (_) => $constructor, settings: settings,');
      if (r.cupertinoNavTitle != null) {
        _write("title:'${r.cupertinoNavTitle}',");
      }
    } else if (r.routeType == RouteType.material) {
      _write(
          'return MaterialPageRoute<$returnType>(builder: (_) => $constructor, settings: settings,');
    } else {
      _write(
          'return PageRouteBuilder<$returnType>(pageBuilder: (ctx, animation, secondaryAnimation) => $constructor, settings: settings,');

      if (r.customRouteOpaque != null) {
        _write('opaque:${r.customRouteOpaque.toString()},');
      }
      if (r.customRouteBarrierDismissible != null) {
        _write(
            'barrierDismissible:${r.customRouteBarrierDismissible.toString()},');
      }
      if (r.transitionBuilder != null) {
        _write('transitionsBuilder: ${r.transitionBuilder.name},');
      }
      if (r.durationInMilliseconds != null) {
        _write(
            'transitionDuration: Duration(milliseconds: ${r.durationInMilliseconds}),');
      }
    }
    // generated shared props
    if (r.fullscreenDialog != null) {
      _write('fullscreenDialog:${r.fullscreenDialog.toString()},');
    }
    if (r.maintainState != null) {
      _write('maintainState:${r.maintainState.toString()},');
    }

    _writeln(');');
  }
}
