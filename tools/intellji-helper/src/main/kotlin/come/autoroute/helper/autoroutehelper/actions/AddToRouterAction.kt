package come.autoroute.helper.autoroutehelper.actions

import JFrameDialog
import com.google.gson.Gson
import com.intellij.codeInsight.actions.ReformatCodeProcessor
import com.intellij.codeInsight.intention.IntentionAction
import com.intellij.openapi.command.WriteCommandAction
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
import come.autoroute.helper.autoroutehelper.utils.PsiUtils
import java.io.File

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

    private var lastModified: Long = -1
    private var routerConfig: RouterConfig? = null

    override fun isAvailable(project: Project, editor: Editor?, file: PsiFile?): Boolean {
        if (file !is DartFile) return false
        val routerConfigFile = File("${project.basePath}${Strings.routeJsonFilePath}")
        if (!routerConfigFile.exists()) return false
        editor?.apply {
            PsiUtils.findPossibleRoutePage(this, file) ?: return false
            val localFileLastModified = routerConfigFile.lastModified()
            if (lastModified != localFileLastModified) {
                lastModified = localFileLastModified
                try {
                    routerConfig = Gson().fromJson(routerConfigFile.readText(), RouterConfig::class.java)
                } catch (e: Exception) {
                    return false
                }

            }
        }
        return true
    }


    override fun invoke(project: Project, editor: Editor?, file: PsiFile?) {
        routerConfig?.let {
            val routesList = PsiUtils.getRoutesList(project, it) ?: return
            editor?.apply {
                val routePageInfo = PsiUtils.findPossibleRoutePage(this, file) ?: return
                JFrameDialog.show(it, routesList, routePageInfo, component, object : DialogDismissListener {
                    override fun onDone(dialog: JFrameDialog) {
                        dialog.apply {
                            document.apply {
                                WriteCommandAction.runWriteCommandAction(project) {
                                    setReadOnly(false)
                                    if (routePageInfo.annotation != null && !routeNameTextField.text.isNullOrBlank() && routePageInfo.customName.isNullOrBlank()) {
                                        insertString(routePageInfo.annotation.endOffset - 1, "name: '${routeNameTextField.text}'")
                                    } else if (routePageInfo.annotation == null) {
                                        val nameArg = if (routeNameTextField.text == it.getRouteName(routePageInfo)) "" else "name: '${routeNameTextField.text}'";
                                        insertString(routePageInfo.classElement.startOffset, "@RoutePage(${nameArg})\n")
                                        PsiUtils.getAutoRouteImportOffsetIfNeeded(file)?.let { offset ->
                                            insertString(offset, "${Strings.autoRouteImport}\n")
                                        }

                                    }
                                }
                            }


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
                                var targetElement: PsiElement = routesList.element
                                if (selectTargetIndex > 0) {
                                    val targetRoute = routeItems[selectTargetIndex - 1]
                                    targetElement = targetRoute.route.element.arguments!!
                                    if (targetRoute.route.children == null) {
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
                    }
                })
            }
        }
    }


}




