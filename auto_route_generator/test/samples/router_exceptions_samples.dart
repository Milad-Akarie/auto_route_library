//import 'package:auto_route/auto_route_annotations.dart';
//import 'package:source_gen_test/annotations.dart';
//
//@ShouldThrow('Class name must be prefixed with \$')
//@MaterialAutoRouter()
//class InvalidRouterClassNamePrefix {}
//
//@ShouldThrow(r'invalidRouterElement is not a class element')
//@MaterialAutoRouter()
//void invalidRouterElement() {}
//
//@ShouldThrow('There can be only one initial route per router')
//@MaterialAutoRouter()
//class $MultiInitialAnnotationsRouter {
//  @initial
//  FakeScreen fakeScreen;
//  @initial
//  SecondScreen secondScreen;
//}
//
//class FakeScreen {}
//class SecondScreen {}
//
//@ShouldThrow('UnknowRoute must have a defualt constructor with a positional String Parameter,'
//    ' MyUnknownRoute(String routeName')
//@MaterialAutoRouter()
//class $InvalidUnknownRouteClass {
//  @unknownRoute
//  FakeScreen fakeScreen;
//}
