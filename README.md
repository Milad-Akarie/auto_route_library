
<p align="center">
<img  src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/nav2.0_support/art/auto_route_logo.svg" height="170">
</p>

<p align="center">
<a href="https://img.shields.io/badge/License-MIT-green"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"></a>
<a href="https://github.com/Milad-Akarie/auto_route_library/stargazers"><img src="https://img.shields.io/github/stars/Milad-Akarie/auto_route_library?style=flat&logo=github&colorB=green&label=stars" alt="stars"></a>  
<a href="https://pub.dev/packages/auto_route/versions/1.0.0-beta.3"><img src="https://img.shields.io/badge/pub-1.0.0.beta.3-orange" alt="pub version"></a>
</p>


- [Installation](#installation)
- [Setup and Usage](#setup-and-usage)
- [Generated routes](#generated-routes)
- [Navigation](#navigation)

### Installation

```yaml
dependencies:
  auto_route: [latest-version]

dev_dependencies:
  auto_route_generator: [latest-version]
  build_runner:
```

### Setup and Usage

---

First create a router placeholder class and annotate it with @MaterialAutoRouter, @CupertinoAutoRouter, @AdaptiveAutoRouter or @CustomAutoRouter.
It's name must be prefixed with **\$** to get a generated class with the same name minus the $.
$AppRouter => AppRouter

##### Note: using \$ prefix is mandatory.

```dart
@MaterialAutoRouter(...config)  //CustomAutoRoute(..config)
class $AppRouter {}
```

#### Declare your AutoRoutes inside of AutoRouter annotation
* paths are optional, if not provided auto-generated paths will be used.
```dart
@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(path: '/': page: HomePage),
    AutoRoute(path: '/books', page: BookListPage),
    AutoRoute(path: '/books/:id', page: BookDetailsPage),
  ],
)
class $AppRouter {}
```

#### Now simply run the generator

Use the [watch] flag to watch the files' system for edits and rebuild as necessary.

```terminal
flutter packages pub run build_runner watch
```

if you want the generator to run one time and exits use

```terminal
flutter packages pub run build_runner build
```

#### Finalize the setup

after you run the generator your router class will be generated, use it as follows:
```dart

   final appRouter = AppRouter()
   ...
  Widget build(BuildContext context){
      return MaterialApp.router(
             routerDelegate: appRouter.delegate(...initialConfig),
             routeInformationParser: appRouter.defaultRouteParser(),
         ),
  }
```
## Generated Routes
---
 A `PageRouteInfo` object will be generated for every declared AutoRoute, These objects hold path information plus strongly-typed page argumented which are extrectd from the page's default constructor.
```dart
class BookListRoute extends PageRouteInfo {
  const BookListRoute() : super(name, path: '/books');

  static const String name = 'BookListRoute';
}
```


## Navigation
---
Use AutoRouter to push `PageRouteInfo` objects instead of named routes (strings).
```dart
AutoRouter.of(context).push(BooksPageRoute())
// or you can use the extension
context.router.push(BooksListRoute())
```

## More docs are coming soon

### Support auto_route
You can support auto_route by liking it on Pub and staring it on Github, sharing ideas on how we can enhance a certain functionality or by reporting any problems you encounter
