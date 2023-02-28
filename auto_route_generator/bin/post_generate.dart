
final content = r'''
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class RootRouter extends $RootRouter {
  @override
  final List<AutoRoute> routes = [
    MaterialRoute(path: '/', name: HomeRoute),
    AutoRoute(path: '/books', name: BookListRoute, children: [
      AutoRoute(name: BookDetailsRoute),
    ]),
  AutoRoute(name: HomeRoute),];
}
''';




void main(List<dynamic> args){
  print('--------- Running post generate');
  // final parsed = parseString(content: content);
  // final clazz = parsed.unit.declarations.first as ClassDeclaration;
  // clazz.members
  // clazz.childEntities
  ;
}