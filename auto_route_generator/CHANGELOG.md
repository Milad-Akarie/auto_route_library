# ChangeLog
##[2.4.0]
- Fix url updates delay
- Fix navigate does not update url
- Add auto_route_information_provider.dart to fix infinite browser back button when using url redirects
- optimize routes rebuild -> only rebuild if route data changes
- Change routers are now not ( Watched ) by default to reduce rebuilds [ may Break]
- Add optional homeIndex property to AutoTabsRouter to make sure we always pop from home tab
- Change AutoBackButton to use StackRouterScope instead of RouterScope
##[2.3.2]
- Merge fix(generator): Bool opt type as num #688
- Fix nested back gesture issue #686
## [2.1.0] Breaking changes!
- adds `void` type to `PageRouteInfo<void>` to become `strong-mode` compliant
## [2.1.0] Breaking changes!
- AutoRouteGuard no longer returns a future<bool> and passes in a resolver. [Breaking]
- Remove onInitialRoutes from AutoRouterDelegate. [Breaking]
- Rename RoutingControllerScope to RouterScope. [Breaking]
- Expose provided navigatorObservers in RouterScope
- Route name is now default page key with option to use path as key.
- Add onNavigate callback function to AutoRouterDelegate
- Add onNavigate all back to AutoRouter.declarative 
- Add declarative option to AutoTabsRouter
## [2.0.1] Breaking changes!
- OnPopRoute includes a results object now. [Breaking]
- Required queryParams to either be nullable or have a default value
## [2.0.0] Breaking changes!
##### breaking changes
- Remove usesTabsRouter property from AutoRoute as it's no longer needed.
- onGenerateRoutes is now shortened to just routes and initial routes are no longer pass
- Legacy generator is completely dropped now.
- Remove all legacy generator related flags.
- navigatorObservers is not a callback function that returns a list of observers
##### enhancements
- Bring back the good old await for pop results feature.
- The root AutoRouterDelegate can now be declarative.
- Push, replace and navigate will now bubble up if they can't be handled by the router they're called from.
- Enhance the navigate function to behave like navigating from the browser's bar.
- Add new methods to navigate by path pushNamed, replaceNamed and navigateNamed.
- Add AutoBackButton to handle nested routers popping with ease.
- Add some helper/shortcut methods to context extension, pushRoute, replaceRoute, navigateTo and popRoute.
- Add some helper methods to the RoutingController like popTop, topRoute and more.
- Pages will rebuild when an ancestor router updates if you depend on it.
- Add Auto RedirectRoute generation for Routes with none initial paths that's marked as initial.
- Add AutoRouteObserver to add tabs observing to the native observer.
- NavigatorObservers are now passed through a builder so nested navigators can inherit them.
- Add HeroControllerScope to nested AutoRouters
- Pomp up code_builder version to 4.0.0 and build_runner to 2.0.1
- Fix #458, #456 #421 and #453
- Minor fixes and enhancements
## [1.0.2]
- Pomp up versions of build, build_runner, dart_style and source_gen
- Using pathParam annotation is not more flexible and has less constrains
- Remove dart:io import to include (web) as a supported platform
- other fixes
## [1.0.1]
- Fix Stack overflow in RootStackRouter popUntilRoot() #401
- Fix path parameters are assigned an undefined var when alias is different than param name.
## [1.0.0]
- Migrate to null-safety
- Add option to pass restoration id
- Add option to specify the root navigator background color
## [1.0.0-beta.11]
- Fix building PageRouteInfo from match does not respect default values
## [1.0.0-beta.10]
- Fix generic parameters crash the generator
- Add support for array type query params
## [1.0.0-beta.8]
- Add support for null-Safety to generated code.
- Fix pop issues
- Add popUntil, popUntilRoot and popUntilRouteWithName helper functions to StackRouter
- Minor fixes
## [1.0.0-beta.7]
- Fix onRoutePop not called in declarative router #310
- Fix App reloads after pressing browser's back button #309
- Fix TabsRouter not displaying current route when pressing the browser's back button
- Add pop until method to StackRouter
- Prefix parent routes are now included if includePrefixMatches is true
- Add RouteMatcher tests
- Minor improvements
## [1.0.0-beta.6]
- Fix reload issue when pressing the browser's back button #309
- Fix onPopRoute is not called in declarative Router #310
- Include empty paths as prefix-matched paths when deep-linking.
- Remove unnecessary dependencies
- Some minor improvements and code refactor
## [1.0.0-beta.5]
- Refactor some code
- Update readme file
## [1.0.0-beta.4]
- Fix page can not be used for multiple routes
- Add duplicate route-names check in generator.
## [1.0.0-beta.2]
- Add lazyLoad option to AutoTabsRouter
- Replace AutoRouterConfig with an implementation of StackRouter
- Root delegate is now lazyLoaded

## [1.0.0-beta.1] Breaking Changes!
- Add TabsAutoRouter
- Refactor some code

## [1.0.0-beta] Breaking Changes!
- Rebuild auto_route to work with Navigator 2.0
-----------------------------------------------

## [0.6.10]
- Restrict analyzer version to ">=0.40.0 <2.0.0"

## [0.6.9]
- Fix generator error running flutter version 1.22
- Fix bar-url not updated in flutter version 1.22 

## [0.6.8] 
- Restrict min analyzer version to 0.39.14
- Restrict min build_runner version to 1.10.1

## [0.6.7] 
- Fix linter warnings in generated file

## [0.6.6] 
- Fix generator error when using 'void' as route return type #168

## [0.6.5] 
- Downgrade path package to >= 1.6.4 to solve conflict with flutter_test 
- Clean up auto_route index file

## [0.6.4] 
- Add usage of const constructors when possible
- Fix material package is only imported if needed
- Fix spelling mistakes in changeLog

## [0.6.3] 
- Fix relative imports issue on windows
- Fix private screen parameters break generated file

## [0.6.2] Breaking Change
- Fix deep linking issue for nested routes
- Change ExtendedNavigator to wrap the native navigator instead of extending it
- Change generated class applies to most of effective dart rules including preferring relative imports
- Change initial route placeholder color to white
- Add extension to BuildContext to easily access the navigator
- Remove NestedNavigator, ExtendedNavigator can be used directly as a nested navigator
- Rename some properties and deprecate their older names
- Remove ExtendedNavigator.ofRouter method 
- Minor fixes and enhancements


## [0.6.0] Breaking Change
- Change the way routes are declared from class fields to a static list
- Add support for path & query parameters
- Add support for path wildcards
- Add support for nested routes
- Add support for generic result types
- Add get ExtendedNavigator by name feature
- Merge fix for adaptive route web support issue
- Change generating arguments holder for single parameter routes is not optional anymore
- Minor fixes and enhancements
## [0.5.0] 
- Add support for Complex function types & typeDef as Route parameters
## [0.4.10] Skip
## [0.4.9] Breaking Changes
- Change generate routes list is no longer optional
- Change Routes.all returns a set instead of List
- Add Route prefix option to AutoRouter
- remove useLeadingSlashes flag from AutoRouter

## [0.4.8] 
- Change PageRouteBuilder context arg name from ctx to context
- Fix args declaration is generated even if there's no routes with args

## [0.4.7] 
- Fix non-core dart types aren't imported

## [0.4.6] Breaking Change
- Add AdaptiveAutoRouter and AdaptiveRoute for native platforms
- Change using leading slashes is now options
- Change wrappedRoute is now a function that takes in build context
- Fix calling nested route returns null after popping parent route
- Fix initial route ignore custom transitions
- Add ability to name routes class

## [0.4.5]

- Fix @unknownRoute generates error

## [0.4.4]

- Change generating arguments holder for single parameter routes is now optional
- Fix android soft back button always pops root navigator

## [0.4.3] Breaking Changes

- Add ability to pass initial route arguments to ExtendedNavigator
- Change single route parameters will have argument holder classes too as requested
- Fix ExtendedNavigator.ofRouter<T>() returns null in inspector mode

## [0.4.0] Breaking Changes

- Change using ExtendedNavigator instead of the native Navigator
- Fix initial route does not go through guards
- Change generated router class is no longer static
- Change routes are generated in their own class now "Routers"
- Add option to generate navigation helper methods extension
- Update README file

## [0.3.2]

- Fix generic arguments are not imported.

## [0.3.1]

- Fix Compilation Fails in flutter 1.15.+
- Fix third party imports src instead of library
- Fix guardedRoutes is generated even if it's empty
- Add support for custom unknown route screen
- upgrade analyzer min restrain to 0.39.2

## [0.3.0] Breaking Changes!

- Add global route customization
  Use MaterialAutoRouter, CupertinoAutoRouter or CustomAutoRouter instead of AutoRouter
- Navigator key is now accessed by calling Router.navigator.key instead of Router.navigatorKey.
- Add Route guards
- Add optional returnType param in all AutoRoute types.
- Remove generate Navigator Key option.
- Fix generate error when using dynamic vars in route widget constructors

## [0.2.2]

- Add option to generate a list with all route names
- change generating navigator key is now optional
- Fix prevent importing system library files
- Change generated route path name are now Kabab cased (url-friendly)
- Add ability to use custom path names in all route types
- Update README file

## [0.2.1+3]

- fix custom route not generating custom properties

## [0.2.1+2]

- fix @required is missing in arguments holder class

## [0.2.1+1]

- fix dependency conflict

## [0.2.1]

- add Route Wrapper
- add initial flag as a property in all route types
- change prefix const route names with class name.
- add fullscreenDialog property to @CustomRoute()

## [0.2.0]

### Breaking Changes!

- change to using a single config file instead of annotating the actual widget class due to performance issues.
- add @MaterialRoute(), @CupertinoRoute() and @CustomRoute() annotations
- remove @AutoRoute() annotation and add @AutoRouter()
- handle required parameters.
- add navigating with a global navigator key [without context].
- support nested navigators.

## [0.1.3]

- fix more dependencies resolving conflict.

## [0.1.2]

- fix dependencies resolving conflict.

## [0.1.1]

- code formatting.

## [0.1.0]

- initial release.
