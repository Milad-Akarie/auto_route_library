package come.autoroute.helper.autoroutehelper.actions

import com.intellij.codeInsight.actions.ReformatCodeProcessor
import com.intellij.codeInsight.intention.IntentionAction
import com.intellij.openapi.command.WriteCommandAction
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.project.Project
import com.intellij.psi.PsiDocumentManager
import com.intellij.psi.PsiFile
import com.intellij.psi.util.PsiTreeUtil
import com.intellij.refactoring.suggested.endOffset
import com.intellij.refactoring.suggested.startOffset
import com.jetbrains.lang.dart.psi.*
import com.jetbrains.lang.dart.util.DartResolveUtil
import come.autoroute.helper.autoroutehelper.Strings
import come.autoroute.helper.autoroutehelper.models.RefactableClass
import come.autoroute.helper.autoroutehelper.models.RefactorResult
import come.autoroute.helper.autoroutehelper.utils.PsiUtils
import come.autoroute.helper.autoroutehelper.utils.Utils

class MigrateToV6Action : IntentionAction {
    override fun startInWriteAction(): Boolean {
        return false
    }

    override fun getText(): String {
        return "Migrate to AutoRoute V6";
    }

    override fun getFamilyName(): String {
        return Strings.familyName
    }

    override fun isAvailable(project: Project, editor: Editor?, file: PsiFile?): Boolean {
        if (file !is DartFile || editor == null) return false
        val clazz = PsiUtils.dartClassAt(file, editor.caretModel.offset) ?: return false
        return findAutoRouterMetaData(clazz) != null
    }


    private fun findAutoRouterMetaData(clazz: DartClassDefinition): DartMetadata? {
        return clazz.metadataList.firstOrNull { m ->
            listOf("MaterialAutoRouter", "CupertinoAutoRouter", "AdaptiveAutoRouter", "CustomAutoRouter").contains(m.referenceExpression.text)
        }
    }

    override fun invoke(project: Project, editor: Editor?, file: PsiFile?) {
        if (file == null || editor == null) return

        PsiDocumentManager.getInstance(project).let {
            it.doPostponedOperationsAndUnblockDocument(editor.document)
            it.commitDocument(editor.document)
        }

        val clazz = PsiUtils.dartClassAt(file, editor.caretModel.offset) ?: return
        val annotation = findAutoRouterMetaData(clazz) ?: return
        val argsList = PsiTreeUtil.getChildOfType(annotation.lastChild, DartArgumentList::class.java)

        val annotationArgsList = PsiTreeUtil.getChildrenOfType(argsList, DartNamedArgument::class.java)
        val routesArg = annotationArgsList?.firstOrNull { it.firstChild.text == "routes" } ?: return
        val replaceInRouteName = Utils.stripStringQts(annotationArgsList.firstOrNull { it.firstChild.text == "replaceInRouteName" }?.lastChild?.text)
        val literalList = routesArg.lastChild as DartListLiteralExpression
        val refactoredRootList = refactor(literalList, replaceInRouteName, true)
        val allClasses = handleReferencedLists(project, refactoredRootList.listRefs, replaceInRouteName).plus(refactoredRootList.classRefs)

        val emptyRouterClasses = allClasses.filter { it.classRef.name == "EmptyRouterPage" || it.classRef.name == "EmptyRouterScreen" }.distinctBy { it.customName }
        handleRefactableClasses(project, allClasses.filterNot { it.classRef.name == "EmptyRouterPage" || it.classRef.name == "EmptyRouterScreen" }.distinctBy { it.classRef })

        editor.document.apply {
            WriteCommandAction.runWriteCommandAction(project) {
                setReadOnly(false)
                insertString(clazz.endOffset, StringBuilder().apply {
                    for (emptyPage in emptyRouterClasses) {
                        val name = if (emptyPage.customName == null) emptyPage.classRef.name!! else Utils.stripStringQts(emptyPage.customName)
                        appendLine("""
                          @RoutePage()
                         class $name extends AutoRouter {
                             const $name({super.key});
                         }
                          """)
                    }
                }.toString())
                val defaultRouteType = annotation.referenceExpression.text!!.replace("AutoRouter", "").lowercase()
                val routeTypeArgsList = ArrayList<String>();
                if (defaultRouteType == "custom") {
                    val customRouteArgs = annotationArgsList.filterNot {
                        listOf("routes", "replaceInRouteName", "deferredLoading", "preferRelativeImports").contains(it.firstChild.text)
                    };
                    if (customRouteArgs.isNotEmpty()) {
                        for (namedArg in customRouteArgs) {
                            routeTypeArgsList.add(namedArg.text)
                        }
                        val nextVisibleElement = PsiTreeUtil.nextVisibleLeaf(customRouteArgs.last())
                        val lastElementToDelete = if (nextVisibleElement?.text == ",") nextVisibleElement else customRouteArgs.first()
                        annotation.deleteChildRange(customRouteArgs.firstOrNull(), lastElementToDelete)
                    }
                }


                val refactoredContent = StringBuilder("@override\nRouteType get defaultRouteType => RouteType.${defaultRouteType}" + "(${routeTypeArgsList.joinToString(",")});")
                refactoredContent.appendLine()
                refactoredContent.append("@override\nfinal List<AutoRoute> routes = ${refactoredRootList.text};")
                insertString(clazz.endOffset - 1, refactoredContent)
                val className = clazz.name!!
                if (className.startsWith("$")) {
                    val strippedClassName = className.subSequence(1, className.length)
                    replaceString(clazz.nameIdentifier!!.startOffset, clazz.nameIdentifier!!.endOffset, "$strippedClassName extends $${strippedClassName}")
                }
                replaceString(annotation.referenceExpression.startOffset, annotation.referenceExpression.endOffset, "AutoRouterConfig")
                ReformatCodeProcessor(file, false).run()
                PsiDocumentManager.getInstance(project).let {
                    it.doPostponedOperationsAndUnblockDocument(this)
                    it.commitDocument(this)
                }
                PsiTreeUtil.nextVisibleLeaf(routesArg)?.let {
                    if (it.text == ",") it.delete()
                }
                routesArg.delete()
            }

        }
        Utils.runBuildRunner(project)
    }

}

private fun handleRefactableClasses(project: Project, list: List<RefactableClass>) {
    val groupedByContainingFile = list.groupBy { it.classRef.containingFile }
    for (file in groupedByContainingFile.keys) {
        for (clazz in groupedByContainingFile[file]!!.sortedByDescending { it.classRef.startOffset }) {
            val classRef = clazz.classRef
            if (classRef.getMetadataByName("RoutePage") != null) return
            FileDocumentManager.getInstance().getDocument(classRef.containingFile.virtualFile)?.apply {
                WriteCommandAction.runWriteCommandAction(project) {
                    setReadOnly(false)
                    val argsList = ArrayList<String>()
                    if (clazz.customName != null) {
                        argsList.add("name: ${clazz.customName}")
                    }
                    if (clazz.deferredLoading != null) {
                        argsList.add("deferredLoading: '${clazz.deferredLoading}'")
                    }
                    insertString(classRef.startOffset, "@RoutePage${clazz.returnType ?: ""}(${argsList.joinToString(",")})\n")
                    PsiUtils.getAutoRouteImportOffsetIfNeeded(classRef.containingFile)?.let { offset ->
                        insertString(offset, "${Strings.autoRouteImport}\n")
                    }
                    PsiDocumentManager.getInstance(project).commitDocument(this);
                }
            }
        }
    }


}

private val alreadyRefactoredLists = ArrayList<DartListLiteralExpression>()
private fun handleReferencedLists(project: Project, refactoredList: List<DartListLiteralExpression>, replaceInRouteName: String?): List<RefactableClass> {
    val refactableClasses = ArrayList<RefactableClass>()
    val groupedByContainingFile = refactoredList.groupBy { it.containingFile }
    for (file in groupedByContainingFile.keys) {
        for (list in groupedByContainingFile[file]!!.sortedByDescending { it.startOffset }) {
            if (alreadyRefactoredLists.contains(list)) continue

            val refactorRes = refactor(list, replaceInRouteName)
            refactableClasses.addAll(refactorRes.classRefs)
            alreadyRefactoredLists.add(list)

            if (refactorRes.listRefs.isNotEmpty()) {
                val classRefsInSubLists = handleReferencedLists(project, refactorRes.listRefs, replaceInRouteName)
                refactableClasses.addAll(classRefsInSubLists)
            }

            FileDocumentManager.getInstance().getDocument(file.virtualFile)?.apply {
                WriteCommandAction.runWriteCommandAction(project) {
                    setReadOnly(false)
                    replaceString(list.startOffset, list.endOffset, refactorRes.text)
                    ReformatCodeProcessor(file, true).run()
                    PsiDocumentManager.getInstance(project).commitDocument(this);
                }
            }

        }

    }
    return refactableClasses
}


private fun refactor(list: DartListLiteralExpression, replaceInRouteName: String?, root: Boolean = false): RefactorResult {
    val classRefs = ArrayList<RefactableClass>()
    val listRefs = ArrayList<DartListLiteralExpression>()
    val sb = StringBuilder("[").apply {
        for (item in list.elementList.map { it.lastChild }) {
            if (item is DartCallExpression) {
                val returnType = item.typeArgumentsList.firstOrNull()?.text
                val argsList = item.lastChild as DartArguments?
                val namedArgs = PsiTreeUtil.getChildrenOfType(argsList?.argumentList, DartNamedArgument::class.java)
                val argsBuilder = ArrayList<String>()
                if (namedArgs != null) {
                    var customName: String? = null
                    var customNameRef: String? = null
                    var deferredLoading: String? = null

                    namedArgs.firstOrNull { it.firstChild.text == "name" }?.let {
                        customNameRef = it.lastChild?.text
                        customName = customNameRef;
                        if (it.lastChild !is DartStringLiteralExpression) {
                            val resolvedVar = DartResolveUtil.findReferenceAndComponentTarget(it.lastChild)?.context
                            customName = PsiTreeUtil.findChildOfType(resolvedVar, DartVarInit::class.java)?.expression?.text
                                    ?: customNameRef
                        }

                    }
                    namedArgs.firstOrNull { it.firstChild.text == "deferredLoading" }?.let {
                        deferredLoading = it.lastChild?.text
                    }

                    for (namedArg in namedArgs.filterNot { listOf("name", "deferredLoading").contains(it.firstChild.text) }) {
                        if (namedArg.firstChild.text == "children") {

                            if (namedArg.lastChild is DartListLiteralExpression) {
                                val childRefactoredRes = refactor(namedArg.lastChild as DartListLiteralExpression, replaceInRouteName)
                                classRefs.addAll(childRefactoredRes.classRefs)
                                listRefs.addAll(childRefactoredRes.listRefs)
                                argsBuilder.add("children: ${childRefactoredRes.text}")
                            } else {
                                if (namedArg.lastChild is DartReferenceExpression) {
                                    val resolvedRef = DartResolveUtil.findReferenceAndComponentTarget(namedArg.lastChild)?.context
                                    val listRef = PsiTreeUtil.findChildOfType(resolvedRef, DartListLiteralExpression::class.java)
                                    if (listRef != null) {
                                        listRefs.add(listRef)
                                    }
                                }
                                argsBuilder.add(namedArg.text)
                            }


                        } else if (namedArg.firstChild.text == "initial") {
                            argsBuilder.add("path: ${if (root) "'/'" else "''"}")
                        } else if (namedArg.firstChild.text == "page") {
                            val pageRef = namedArg.lastChild
                            val clazzRef = DartResolveUtil.findReferenceAndComponentTarget(pageRef)
                            if (clazzRef != null) {
                                classRefs.add(RefactableClass(clazzRef, customNameRef, deferredLoading, returnType))
                            }
                            val routeName = Utils.resolveRouteName(pageRef.text, Utils.stripStringQts(customName), replaceInRouteName)
                            argsBuilder.add("page: ${routeName}.page")
                        } else {
                            argsBuilder.add(namedArg.text)
                        }
                    }
                }
                append("${item.firstChild.text}(${argsBuilder.joinToString(",")}),")
            } else {
                if (item is DartSpreadElement) {
                    val spreadListRef = DartResolveUtil.findReferenceAndComponentTarget(item.lastChild)?.context
                    val spreadListLiteral = PsiTreeUtil.findChildOfType(spreadListRef, DartListLiteralExpression::class.java)
                    if (spreadListLiteral != null) {
                        listRefs.add(spreadListLiteral)
                    }
                }
                append(item.text)
            }
        }
        append("]")
    }.toString()

    return RefactorResult(sb, classRefs, listRefs)
}







