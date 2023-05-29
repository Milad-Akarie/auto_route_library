package come.autoroute.helper.autoroutehelper.services

import com.google.gson.Gson
import com.intellij.openapi.project.Project
import come.autoroute.helper.autoroutehelper.Strings
import come.autoroute.helper.autoroutehelper.models.RouterConfig
import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.stream.Collectors
import kotlin.io.path.pathString


class RouterConfigService(private val project: Project) {
    private var lastModified: Long = -1
    private var routerConfig: RouterConfig? = null
    private var routerConfigFile: File? = null


    fun getConfig(): RouterConfig? {
        if (routerConfigFile == null) {
            findConfigFile(Strings.routerConfigFileExt, project.basePath!!)?.let {
                if (it.isNotEmpty()) {
                    routerConfigFile = it.first().toFile()
                }
            }
        }

        if (routerConfigFile?.exists()  != true) return null
        val localFileLastModified = routerConfigFile!!.lastModified()
        if (lastModified != localFileLastModified) {
            lastModified = localFileLastModified
            return try {
                routerConfigFile?.let { file->
                routerConfig = Gson().fromJson(file.readText(), RouterConfig::class.java)
                  val pathSegments =file.path.split("/")
                    val dartToolSegmentIndex = pathSegments.indexOf(".dart_tool")
                     if(dartToolSegmentIndex != -1){
                         val cleaned =  pathSegments.filterIndexed{ index, _ ->  !IntRange(dartToolSegmentIndex,dartToolSegmentIndex+3).contains(index)}
                         val path = cleaned.joinToString("/").replaceFirst("router_config.json","dart")
                         routerConfig?.path = path
                     }
                routerConfig
                }
            } catch (e: Exception) {
                return routerConfig
            }

        }
        return routerConfig
    }

    @Throws(IOException::class)
    fun findConfigFile(fileExt: String, searchDirectory: String): Collection<Path>? {
        Files.walk(Paths.get(searchDirectory)).use { files ->
            return files
                    .filter { f ->
                        f.fileName.pathString.endsWith(fileExt) }
                    .collect(Collectors.toList())
        }
    }


}