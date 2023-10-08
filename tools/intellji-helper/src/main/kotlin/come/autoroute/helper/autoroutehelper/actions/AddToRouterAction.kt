package come.autoroute.helper.autoroutehelper.actions

import JFrameDialog
import com.intellij.codeInsight.actions.ReformatCodeProcessor
import com.intellij.codeInsight.intention.IntentionAction
import com.intellij.openapi.command.WriteCommandAction
import com.intellij.openapi.components.service
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.project.Project
import com.intellij.psi.PsiDocumentManager
import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import com.intellij.psi.util.PsiTreeUtil
import com.intellij.refactoring.suggested.endOffset
import com.intellij.refactoring.suggested.startOffset
import com.jetbrains.lang.dart.psi.DartFile
import com.jetbrains.lang.dart.psi.DartListLiteralExpression
import come.autoroute.helper.autoroutehelper.Strings
import come.autoroute.helper.autoroutehelper.listeners.DialogDismissListener
import come.autoroute.helper.autoroutehelper.models.RouterConfig
import come.autoroute.helper.autoroutehelper.services.RouterConfigService
import come.autoroute.helper.autoroutehelper.services.SettingsService
import come.autoroute.helper.autoroutehelper.utils.PsiUtils
import come.autoroute.helper.autoroutehelper.utils.Utils

class AddToRouterAction : IntentionAction {
    override fun startInWriteAction(): Boolean {
        return false
    }


    override fun getText(): String {
        return "Add to ${routerConfig?.routerClassName ?: "Router"}"
    }

    override fun getFamilyName(): String {
        return Strings.familyName
    }

    private var routerConfig: RouterConfig? = null

    override fun isAvailable(project: Project, editor: Editor?, file: PsiFile?): Boolean {
        if (file !is DartFile) return false
        routerConfig = project.service<RouterConfigService>().getConfig() ?: return false
        editor?.apply {
            PsiUtils.findPossibleRoutePage(this, file) ?: return false
        }
        return true
    }


    override fun invoke(project: Project, editor: Editor?, file: PsiFile?) {
        routerConfig?.let {
            val routesList = PsiUtils.getRoutesList(project, it) ?: return
            editor?.apply {
                val routePageInfo = PsiUtils.findPossibleRoutePage(this, file) ?: return
                val settingsService = project.service<SettingsService>()
                JFrameDialog.show(
                    it,
                    routesList,
                    routePageInfo,
                    component.rootPane,
                    settingsService,
                    object : DialogDismissListener {
                        override fun onDone(dialog: JFrameDialog) {
                            dialog.apply {
                                document.apply {
                                    WriteCommandAction.runWriteCommandAction(project) {
                                        setReadOnly(false)
                                        if (routePageInfo.annotation != null && !routeNameTextField.text.isNullOrBlank() && routePageInfo.customName.isNullOrBlank()) {
                                            insertString(
                                                routePageInfo.annotation.endOffset - 1,
                                                "name: '${routeNameTextField.text}'"
                                            )
                                        } else if (routePageInfo.annotation == null) {
                                            insertString(
                                                routePageInfo.classElement.startOffset,
                                                dialog.getAnnotationText(routePageInfo.classElement.name!!)
                                            )
                                            PsiUtils.getAutoRouteImportOffsetIfNeeded(file)
                                                ?.let { offset ->
                                                    insertString(
                                                        offset,
                                                        "${Strings.autoRouteImport}\n"
                                                    )
                                                }
                                        }
                                    }
                                }

                                addToRouter(project)
                                if (settingsService.runBuildRunnerOnSave) {
                                    Utils.runBuildRunner(project)
                                }
                            }
                        }
                    })
            }
        }
    }


}


fun JFrameDialog.getAnnotationText(className: String): String {
    val args = ArrayList<String>();
    if (routeNameTextField.text.isNotBlank()) {
        val resolvedName = Utils.resolveRouteName(
            className,
            null,
            router.replaceInRouteName,
        )
        if (resolvedName != routeNameTextField.text) {
            args.add("name: '${routeNameTextField.text}'")
        }
    }
    if (deferredWebOnlyCheckBox.isSelected) {
        args.add("deferredLoading: true")
    }
    return "@RoutePage(${args.joinToString(",")})\n"
}

fun JFrameDialog.addToRouter(project: Project) {
    StringBuilder("AutoRoute(").let { b ->
        val argsList = mutableListOf<String>()
        if (pathTextField.text.isNotBlank()) argsList.add("path: '${pathTextField.text}'")
        argsList.add("page: ${routeNameTextField.text}.page")
        if (!maintainStateCheckBox.isSelected) argsList.add("maintainState: false")
        if (fullscreenDialogCheckBox.isSelected) argsList.add("fullscreenDialog: true")
        if (fullPathMatchCheckBox.isSelected) argsList.add("fullMatch: true")
        b.append(argsList.joinToString(","))
        if (argsList.size > 3) b.append(",")
        b.append("),")

        val selectTargetIndex = targetListCombo.selectedIndex
        var targetElement: PsiElement = routeItems.first().list.element
        if (selectTargetIndex > 0) {
            val targetRoute = routeItems[selectTargetIndex - 1]
            if (targetRoute.route.children == null) {
                targetElement = targetRoute.route.element.arguments!!
                b.insert(0, "children:[")
                b.append("],")
            } else {
                targetElement = targetRoute.route.children.element
            }
        }

        if (PsiTreeUtil.prevVisibleLeaf(targetElement.lastChild)?.text != "," && (targetElement !is DartListLiteralExpression || targetElement.elementList.isNotEmpty())) {
            b.insert(0, ',')
        }

        FileDocumentManager.getInstance().getDocument(targetElement.containingFile.virtualFile)?.apply {
            WriteCommandAction.runWriteCommandAction(project) {
                setReadOnly(false)
                insertString(targetElement.endOffset - 1, b.toString())
                ReformatCodeProcessor(targetElement.containingFile, false).run()
                PsiDocumentManager.getInstance(project).commitDocument(this)
            }
        }
    }
}



