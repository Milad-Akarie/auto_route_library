package come.autoroute.helper.autoroutehelper.models

import come.autoroute.helper.autoroutehelper.utils.Utils

data class RouterConfig(
        val routerClassName: String,
        val replaceInRouteName: String?,
        val path: String,
        val deferredLoading: Boolean,
        val usesPartBuilder: Boolean,
) {
    fun getRouteName(result: RoutePageInfo): String {
        return Utils.resolveRouteName(result.classElement.name!!,
                result.customName, replaceInRouteName)
    }
}