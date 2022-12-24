package come.autoroute.helper.autoroutehelper.models

import com.intellij.psi.PsiElement


data class RoutesList(val routes: List<RegisteredRoute>, val element: PsiElement) {
    fun flatten(dept: Int = 0): ArrayList<FlatRouteItem> {
        return routes.fold(ArrayList()) { acc, a ->
            acc.apply { addAll(a.flatten(this@RoutesList,dept)) }
        }
    }
}

data class RegisteredRoute(val name: String, val children: RoutesList? = null, val element: PsiElement) {
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