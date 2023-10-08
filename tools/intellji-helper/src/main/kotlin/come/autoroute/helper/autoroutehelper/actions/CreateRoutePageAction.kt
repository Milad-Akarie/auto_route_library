package come.autoroute.helper.autoroutehelper.actions

import JFrameDialog
import com.intellij.openapi.actionSystem.ActionUpdateThread
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.command.WriteCommandAction
import com.intellij.openapi.components.service
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.pom.Navigatable
import com.intellij.psi.PsiDirectory
import com.intellij.psi.PsiFile
import come.autoroute.helper.autoroutehelper.listeners.DialogDismissListener
import come.autoroute.helper.autoroutehelper.services.RouterConfigService
import come.autoroute.helper.autoroutehelper.services.SettingsService
import come.autoroute.helper.autoroutehelper.utils.PsiUtils
import come.autoroute.helper.autoroutehelper.utils.Utils
import javax.swing.JWindow

class CreateRoutePageAction : AnAction() {

    override fun getActionUpdateThread(): ActionUpdateThread {
        return ActionUpdateThread.EDT
    }

    override fun update(e: AnActionEvent) {
        if (e.project == null) {
            e.presentation.isEnabledAndVisible = false
        } else e.presentation.isEnabledAndVisible = e.project!!.service<RouterConfigService>().getConfig() != null
    }

    override fun actionPerformed(e: AnActionEvent) {
        val project: Project = e.project ?: return

        val navElement = e.getData(CommonDataKeys.NAVIGATABLE) ?: return
        val routerConfig = project.service<RouterConfigService>().getConfig() ?: return
        val routesList = PsiUtils.getRoutesList(project, routerConfig) ?: return
        val source = e.inputEvent?.source
        val component = if (source is JWindow) source.rootPane else null
        JFrameDialog.show(
                routerConfig,
                routesList,
                null,
                component,
                project.service<SettingsService>(),
                object : DialogDismissListener {
                    override fun onDone(dialog: JFrameDialog) {
                        dialog.addToRouter(project)
                        createFile(project, dialog.fileNameField.text, navElement, this) { file ->
                            FileDocumentManager.getInstance().getDocument(file)?.apply {
                                WriteCommandAction.runWriteCommandAction(project) {
                                    val className =
                                            dialog.resolveClassName() ?: return@runWriteCommandAction
                                    insertString(
                                            0,
                                            createPageContent(
                                                    className,
                                                    dialog.getAnnotationText(className)
                                            )
                                    )
                                }
                            }
                            if (project.service<SettingsService>().runBuildRunnerOnSave) {
                                Utils.runBuildRunner(project)
                            }
                        }
                    }
                })


    }
}

private fun createFile(
        project: Project,
        path: String,
        navElement: Navigatable,
        requester: Any,
        onCreated: (file: VirtualFile) -> Unit
) {
    val dir =
            if (navElement is PsiDirectory) navElement else if (navElement is PsiFile) navElement.containingDirectory else return
    val segments = path.split('/').filterNot { it.isBlank() }
    var virtualDir = dir.virtualFile
    WriteCommandAction.runWriteCommandAction(project) {
        for (segment in segments) {
            if (segment == segments.last()) {
                onCreated(virtualDir.createChildData(requester, "$segment.dart"))
            } else {
                virtualDir = virtualDir.createChildDirectory(requester, segment)
            }
        }
    }
}

private fun createPageContent(className: String, annotationText: String): String {
    return "import 'package:flutter/material.dart';\nimport 'package:auto_route/auto_route.dart';\n\n${annotationText}class $className extends StatelessWidget {\n  const $className({super.key});\n  @override\n  Widget build(BuildContext context) {\n    return Container();\n  }\n}\n"
}
