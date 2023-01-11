package come.autoroute.helper.autoroutehelper.models

import com.jetbrains.lang.dart.psi.DartCallExpression
import com.jetbrains.lang.dart.psi.DartListLiteralExpression


data class RoutesList(val routes: List<RegisteredRoute>, val element: DartListLiteralExpression) {
    fun flatten(dept: Int = 0): ArrayList<FlatRouteItem> {
        return routes.fold(ArrayList()) { acc, a ->
            acc.apply { addAll(a.flatten(this@RoutesList,dept)) }
        }
    }

    fun collectAllLists() : List<DartListLiteralExpression>{
        return  mutableListOf(element).apply {
             for(childList in routes.mapNotNull { it.children }) {
                 addAll(childList.collectAllLists())
             }
        }
    }
    override fun equals(other: Any?): Boolean {
         return  other is RoutesList && element  == other.element
    }
}

data class RegisteredRoute(val name: String, val children: RoutesList? = null, val element: DartCallExpression) {
    fun flatten(parentList: RoutesList, dept: Int): ArrayList<FlatRouteItem> {
        val list = ArrayList<FlatRouteItem>();
        list.add(FlatRouteItem(this, parentList,dept))
        if (children != null) {
            list.addAll(children.flatten(dept + 1))
        }
        return  list;
    }
}

class FlatRouteItem(val route: RegisteredRoute, val list: RoutesList, val dept:Int)