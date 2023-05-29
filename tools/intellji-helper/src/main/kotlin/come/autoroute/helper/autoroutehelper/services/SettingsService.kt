package come.autoroute.helper.autoroutehelper.services

import com.intellij.openapi.components.*
import com.intellij.util.xmlb.XmlSerializerUtil

@State(
    name = "autoroute-helper-config",
//    storages = [Storage("autoroute-helper-config.xml")]
)
class SettingsService : PersistentStateComponent<SettingsService> {

    var runBuildRunnerOnSave: Boolean = true
    override fun getState(): SettingsService {
        return this
    }

    override fun loadState(state: SettingsService) {
        XmlSerializerUtil.copyBean(state, this);
    }


}

