package come.autoroute.helper.autoroutehelper.services

import com.google.gson.Gson
import com.intellij.openapi.project.Project
import come.autoroute.helper.autoroutehelper.Strings
import come.autoroute.helper.autoroutehelper.models.RouterConfig
import java.io.File

class RouterConfigService(project: Project) {
    private var lastModified: Long = -1
    private var routerConfig: RouterConfig? = null
    private val routerConfigFile = File("${project.basePath}${Strings.routeJsonFilePath}")
    fun getConfig(): RouterConfig? {
        if (!routerConfigFile.exists()) return null
        val localFileLastModified = routerConfigFile.lastModified()
        if (lastModified != localFileLastModified) {
            lastModified = localFileLastModified
            return try {
                routerConfig = Gson().fromJson(routerConfigFile.readText(), RouterConfig::class.java)
                routerConfig
            } catch (e: Exception) {
                return routerConfig
            }

        }
        return routerConfig
    }

}