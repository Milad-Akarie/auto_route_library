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
##[2.3.1]
- Fix navigate to nested routes open last visited nested route #676
- Add pop parent route support in AutoBackButton
##[2.3.0]
- Fix crash when passing non-string values as query params #606
- Update analyzer version to 2.0.0
- Update build_runner,build and source_gen versions
- Merge #616 Export navigation failure
- Merge #550 Enable AutoTabsScaffold to support custom appbar [Breaking]
- Update README file
## [2.2.1] 
- Fix crash when passing non-string values as query params #606
- Update analyzer version to 2.0.0
- Update build_runner,build and source_gen versions
## [2.2.0] Breaking changes!
- Remove helper methods pushToChild and replaceInChild from TabsRouter [Bad idea]. [Breaking]
- Add navigate and navigateNamed methods to TabsRouter
- Add navigateNamedTo method to context extension
- Change context.navigateTo and context.navigateNamedTo will be fired 
  by nearest RouterScope weather it's a StackRouter or a TabsRouter
- Fix AutoRouteGuard is not fired when route is updating #517
- Fix DidInitTabRoute method is fired when a route is pushed in AutoRouteAware widgets #518
## [2.1.1] Breaking changes!
- AutoRouteGuard's canNavigate method is now called onNavigation. [Breaking]
- Add AutoRouteObserver to add support tab route observing.
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
- Remove usesTabsRouter property from AutoRoute as it's no longer needed.
- Required queryParams to either be nullable or have a default value
## [2.0.0] Breaking changes!
##### breaking changes
- Remove usesTabsRouter property from AutoRoute as it's no longer needed.
- onGenerateRoutes is now shortened to just routes and initial routes are no longer pass
- Legacy generator is completely dropped now.
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
## [1.0.0-beta.10]
- Fix generic parameters crash the generator
- Add support for array type query params
## [1.0.0-beta.9]
- Fix navigatorKey state is lost on hot reload
- Add stackRouterOfIndex getter function to AutoTabsRouter
## [1.0.0-beta.8]
- Add support for null-Safety to generated code.
- Fix pop issues
- Add popUntil, popUntilRoot and popUntilRouteWithName helper functions to StackRouter
- Minor fixes
Edit [BC] pushAndPopUntil uses the native predicate now.
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
## [1.0.0-beta.3+1]
- Fix badge alignment in readme file
## [1.0.0-beta.3]
- Fix crash on empty path deep-linking
- Fix parent does not take priority when child can't pop
- Change includePrefixMatches default value to false in DefaultRouteParser
- Add some updates to Readme file
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
## [0.6.9]
- Fix generator error running flutter version 1.22
- Fix bar-url not updated in flutter version 1.22 
## [0.6.7] 
- Fix blue screen issue when using guards on initial route #189
- Fix relative import issues
- Add option to not prefer relative imports 
- Fix some linter warnings
- Fix issue #176
## [0.6.6] 
- Fix hot reload issue #170
- Fix Hero animations not working with the new ExtendedNavigator # 169 
- Add static builder to ExtendedNavigator to use with MaterialApp's builder

## [0.6.5] 
- Downgrade path package to >= 1.6.4 to solve conflict with flutter_test 
- Clean up auto_route index file

## [0.6.4] 
- Add usage of const constructors when possible
- Fix material package is only imported if needed
- Fix spelling mistakes in changeLog

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

## [0.6.1]
- Fix pop until name issue by implementing PopUntilPath and RouteData.withPath
- Fix opening deep links in new tabs pushes initial route only
## [0.6.0+1]
- Fix README file links
## [0.6.0] Breaking Change
- Change the way routes are declared from class fields to a static list
- Add support for path & query parameters
- Add support for path wildcards
- Add support for nested routes
- Add support for generic result types
- Add a get ExtendedNavigator by name feature
- Merge a fix for adaptive route web support issue
- Change generating arguments holder for single parameter routes is not optional anymore
- Minor fixes and enhancements

## [0.5.0] 
- Add allRoutes getter to RouterBase
- minor fixes
## [0.4.6] Skip
## [0.4.5] Breaking Change
- Add AdaptiveAutoRouter and AdaptiveRoute for native platforms
- Change using leading slashes is now options
- Change wrappedRoute is now a function that takes in build context
- Fix calling nested route returns null after popping parent route
- Fix initial route ignore custom transitions
- Add ability to name routes class

## [0.4.4]

- Change generating arguments holder for single parameter routes is not optional
- Fix android soft back button always pops root navigator

## [0.4.3] Breaking Changes

- Add ability to pass initial route arguments to ExtendedNavigator
- Change single route parameters will have argument holder classes too as requested
- Fix ExtendedNavigator.ofRouter<T>() returns null in inspector mode

## [0.4.2]

- Fix Android soft back button always exists App

## [0.4.1] Breaking Changes

- Fix isInitialRoute not defined for RouteSettings in flutter 1.15.+

## [0.4.0] Breaking Changes

- Change using ExtendedNavigator instead of the native Navigator
- Fix initial route does not go through guards
- Change generated router class is no longer static
- Change routes are generated in their own class now "Routers"
- Add option to generate navigation helper methods extension
- Update README file

## [0.3.1]

- Fix Compilation Fails in flutter 1.15.+
- Fix third party imports src instead of library
- Fix guardedRoutes is generated even if it's empty
- Add support for custom unknown route screen

## [0.3.0] Breaking Changes!

- Add global route customization
- Use MaterialAutoRouter, CupertinoAutoRouter or CustomAutoRouter instead of AutoRouter
- Navigator key is now accessed by calling Router.navigator.key instead of Router.navigatorKey.
- Add Route guards
- Add optional returnType param in all AutoRoute types.
- Remove generate Navigator Key optional.
- Fix generate error when using dynamic vars in route widget constructors

## [0.2.2]

- Add option to generate a list with all route names
- change generating navigator key is now optional
- Fix prevent importing system library files
- Change generated route path name are now Kabab cased (url-friendly)
- Add ability to use custom path names in all route types
- Update README file

## [0.2.1]

- add Route Wrapper
- add initial flag as a property in all route types
- change prefix const route names with class name.
- add fullscreenDialog property to @CustomRoute()

## [0.2.0+1]

- format README file

## [0.2.0]

### Breaking Changes!

- change to using a single config file instead of annotating the actual widget class due to performance issues.
- add @MaterialRoute(), @CupertinoRoute() and @CustomRoute() annotations
- remove @AutoRoute() annotation and add @AutoRouter()
- handle required parameters.
- add navigating with a global navigator key [without context].
- support nested navigators.

## [0.1.1]

- code formatting.

## [0.1.0]

- initial release.
