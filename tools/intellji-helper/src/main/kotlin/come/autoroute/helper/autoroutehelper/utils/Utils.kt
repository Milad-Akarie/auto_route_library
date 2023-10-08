package come.autoroute.helper.autoroutehelper.utils

import com.intellij.openapi.components.service
import com.intellij.openapi.project.Project
import come.autoroute.helper.autoroutehelper.services.RouterConfigService
import org.jetbrains.plugins.terminal.TerminalView

class Utils {
    companion object {
        fun resolveRouteName(className: String, customName: String?, replaceInRouteName: String?): String {
            if (customName != null) return customName
            if (replaceInRouteName != null && replaceInRouteName.split(',').size == 2) {
                val parts = replaceInRouteName.split(',')
                return className.replaceFirst(parts[0].toRegex(), parts[1])
            }
            return className
        }

        fun stripStringQts(s: String?): String? {
            return s?.replace(Regex("['|\"]"), "")
        }

        fun runBuildRunner(project: Project) {
            val routerConfig  = project.service<RouterConfigService>().getConfig() ?: return
            val path = routerConfig.path.split("/").dropLast(1).joinToString("/")
            val shellTerminalWidget = TerminalView.getInstance(project).createLocalShellWidget(path, "build_runner")
            shellTerminalWidget.executeCommand("dart run build_runner build --delete-conflicting-outputs && exit")
        }
    }
}