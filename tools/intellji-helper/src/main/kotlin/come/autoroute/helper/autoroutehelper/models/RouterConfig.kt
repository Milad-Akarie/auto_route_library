package come.autoroute.helper.autoroutehelper.models

data class RouterConfig(
        val routerClassName: String,
        val replaceInRouteName: String?,
        val path: String,
        val deferredLoading: Boolean,
        val usesPartBuilder: Boolean,
) {
    fun getRouteName(result: RoutePageInfo): String {
        if (result.customName != null) return result.customName
        if (replaceInRouteName != null && replaceInRouteName.split(',').size == 2) {
            val parts = replaceInRouteName.split(',');
            return result.className.replaceFirst(parts[0].toRegex(), parts[1]);
        }
        return result.className
    }
}