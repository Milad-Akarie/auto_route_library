import 'package:auto_route_annotation/src/route_builder_config.dart';
import 'package:auto_route_annotation/src/string_utils.dart';

class RouterClassGenerator {
  final List<RouteConfig> routes;

  final StringBuffer _stringBuffer = StringBuffer();

  RouterClassGenerator(this.routes);

  // helper functions
  _write(Object obj) => _stringBuffer.write(obj);

  _writeln([Object obj]) => _stringBuffer.writeln(obj);

  _newLine() => _stringBuffer.writeln();

  String generate() {
    _generateImports();
    _newLine();
    _writeln("class Router {");
    _generateRouteNames();
    _generateRouteGeneratorFunction();

    // close router class
    _writeln("}");
    _generateArgumentHolders();
    return _stringBuffer.toString();
  }

  void _generateImports() {
    _writeln("import 'package:flutter/material.dart';");
    routes.forEach((r) => _writeln(r.import));
  }

  void _generateRouteNames() {
    _newLine();
    routes.forEach((r) {
      final routeName = _routeNameFromClassName(r.className);
      return _writeln(" static const $routeName = '/${routeName}';");
    });
  }

  _routeNameFromClassName(String className) {
    final name = toLowerCamelCase(className);
    return "${name}Route";
  }

  void _generateRouteGeneratorFunction() {
    _newLine();
    _writeln("static Route<dynamic> onGenerateRoute(RouteSettings settings) {");
    _writeln("final args = settings.arguments;");
    _writeln("switch (settings.name) {");
    routes.forEach((r) => generateRoute(r));

    _generateUnknownRoutePage();
    // close switch case
    _writeln("}");
    _newLine();

    // close onGenerateRoute function
    _writeln("}");
  }

  generateRoute(RouteConfig r) {
    _writeln("case ${_routeNameFromClassName(r.className)}:");

    StringBuffer constructorParams = StringBuffer("");

    if (r.parameters != null && r.parameters.isNotEmpty) {
      if (r.parameters.length == 1) {
        final param = r.parameters[0];

        // throw in exception if passed args are not the same as declared args
        _writeln("if (args is! ${param.type}) throw ('Expected ${param.type} found \${args.runtimeType}');");
        if (param.isPositional)
          constructorParams.write("args as ${param.type}");
        else
          constructorParams.write("${param.name}:args as ${param.type}");
      } else {
        // throw in exception if passed args are not the same as declared args
        _writeln(
            "if (args is! ${r.className}Arguments) throw ('Expected ${r.className}Arguments found \${args.runtimeType}');");
        _writeln("final typedArgs = args as ${r.className}Arguments;");

        r.parameters.asMap().forEach((i, param) {
          if (param.isPositional)
            constructorParams.write("typedArgs.${param.name}");
          else
            constructorParams.write("${param.name}:typedArgs.${param.name}");

          if (i != r.parameters.length - 1) constructorParams.write(",");
        });
      }
    }
    _writeln(
        "return MaterialPageRoute(builder: (_) => ${r.className}(${constructorParams.toString()}), settings: settings);");
    _writeln("break;");
  }

  void _generateUnknownRoutePage() {
    _writeln("default:");
    _writeln(
        "return MaterialPageRoute(builder: (_) => \n Scaffold(body: \n Container(color: Colors.redAccent,\n child: Center(\n  child: Text(\n 'Route name \${settings.name} is not registered'),),),),);");
  }

  void _generateArgumentHolders() {
    _newLine();
    _writeln("//----------------------------------------------");
    final routesWithArgsHolders = routes.where((r) => r.parameters != null && r.parameters.length > 1);
    routesWithArgsHolders.forEach((r) {
      _generateArgsHolder(r);
    });
  }

  void _generateArgsHolder(RouteConfig r) {
    _writeln("//${r.className} arguments holder class");
    final argsClassName = "${r.className}Arguments";

    _writeln("class $argsClassName{");
    r.parameters.forEach((param) {
      _writeln("final ${param.type} ${param.name};");
    });

    _writeln("$argsClassName({");
    r.parameters.asMap().forEach((i, param) {
      _write("this.${param.name}");
      if (i != r.parameters.length - 1) _write(",");
    });
    _writeln("});");

    _writeln("}");
  }
}
