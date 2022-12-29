package come.autoroute.helper.autoroutehelper.utils

class Utils {
    companion object {
        fun resolveRouteName(className: String, customName: String?, replaceInRouteName: String?): String {
            if (customName != null) return customName
            if (replaceInRouteName != null && replaceInRouteName.split(',').size == 2) {
                val parts = replaceInRouteName.split(',');
                return className.replaceFirst(parts[0].toRegex(), parts[1]);
            }
            return className
        }

        fun stripStringQuots(s: String?): String? {
            return s?.replace(Regex("['|\"]"), "");
        }
    }
}