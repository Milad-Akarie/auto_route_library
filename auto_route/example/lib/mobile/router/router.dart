import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/books/book_details_page.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:flutter/cupertino.dart';

import '../screens/books/routes.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile/routes.dart';
import '../screens/settings.dart';
import '../screens/user-data/routes.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
	replaceInRouteName: 'Page,Route',
	routes: <AutoRoute>[
		// app stack
		AutoRoute(
			path: '/',
			page: HomePage,
			children: [
				AutoRoute(
					path: 'books',
					page: EmptyRouterPage,
					name: 'BooksTab',
					children: [
						AutoRoute(path: '', page: BookListPage),
						AutoRoute(
							path: ':id',
							usesPathAsKey: true,
							page: BookDetailsPage,
							// guards: [AuthGuard],
						),
					],
				),
				profileTab,
				AutoRoute(
					path: 'settings/:tab',
					page: SettingsPage,
					name: 'SettingsTab',
				),
			],
		),
		userDataRoutes,
		// auth
		CustomRoute(
			path: '/login',
			page: LoginPage,
			customRouteBuilder: myCustomRouteBuilder,
		),
		RedirectRoute(path: '*', redirectTo: '/'),
	],
)
class $RootRouter {}

typedef CustomRouteBuilder = Route<T> Function<T>(
		BuildContext context, Widget child, CustomPage page);

Route<T> myCustomRouteBuilder<T>(BuildContext context, Widget child, CustomPage<T> page) {
	return PageRouteBuilder(
			fullscreenDialog: page.fullscreenDialog,
			// this's important
			settings: page,
			pageBuilder: (,__, ___)=> child);
}