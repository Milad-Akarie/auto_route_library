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
import come.autoroute.helper.autoroutehelper.models.RoutesList
import come.autoroute.helper.autoroutehelper.utils.PsiUtils
import come.autoroute.helper.autoroutehelper.utils.Utils

class MigrateToV6Action : IntentionAction {
    override fun startInWriteAction(): Boolean {
        return false
    }

    override fun getText(): String {
        return "Migrate To AutoRoute V6";
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
        val clazz = PsiUtils.dartClassAt(file, editor.caretModel.offset) ?: return
        val annotation = findAutoRouterMetaData(clazz) ?: return
        val argsList = PsiTreeUtil.getChildOfType(annotation.lastChild, DartArgumentList::class.java);
        val namedArgsList = PsiTreeUtil.getChildrenOfType(argsList, DartNamedArgument::class.java);
        val routesArg = namedArgsList?.firstOrNull { it.firstChild.text == "routes" } ?: return

        val replaceInRouteName = Utils.stripStringQuots(namedArgsList.firstOrNull { it.firstChild.text == "replaceInRouteName" }?.lastChild?.text)
        val literalList = routesArg.lastChild as DartListLiteralExpression
        val routeList = PsiUtils.getRoutes(literalList)

        editor.document.apply {
            WriteCommandAction.runWriteCommandAction(project) {
                setReadOnly(false)
                val flatRoutes = RoutesList(routeList, literalList).flatten()
                val allReferencedLists = flatRoutes.associateBy { it.list.element }.map { it.key }
                val refactoredList = refactor(allReferencedLists.first(), replaceInRouteName)
                PsiTreeUtil.nextVisibleLeaf(routesArg)?.let {
                    if (it.text == ",") it.delete()
                }
                routesArg.delete()
                insertString(clazz.endOffset - 1, "@override\nfinal List<AutoRoute> routes = ${refactoredList.first};")
                val strippedClassName = clazz.name!!.subSequence(1, clazz.name!!.length)
                replaceString(clazz.nameIdentifier!!.startOffset, clazz.nameIdentifier!!.endOffset, "$strippedClassName extends $${strippedClassName}")
                replaceString(annotation.referenceExpression.startOffset, annotation.referenceExpression.endOffset, "AutoRouterConfig")
                ReformatCodeProcessor(file, false).run()
                PsiDocumentManager.getInstance(project).commitDocument(this)
            }
        }


    }

    private fun refactor(list: DartListLiteralExpression, replaceInRouteName: String?): Pair<String, List<RefactableClass>> {
        val classRefs = ArrayList<RefactableClass>()
        val sb = StringBuilder("[").apply {
            var customName: String? = null
            for (item in list.elementList) {
                val argsList = item.expression?.lastChild as DartArguments?;
                val namedArgs = PsiTreeUtil.getChildrenOfType(argsList?.argumentList, DartNamedArgument::class.java)

                var itemText = item.text;
                if (namedArgs != null)
                    for (namedArg in namedArgs.reversed()) {
                        if (namedArg.firstChild.text == "name") {
                            customName = Utils.stripStringQuots(namedArg?.lastChild?.text)
                            if (namedArg != null) {
                                val nextVisibleLeaf = PsiTreeUtil.nextVisibleLeaf(namedArg);
                                val rangeEnd = if (nextVisibleLeaf?.text == ",") nextVisibleLeaf else namedArg
                                argsList?.argumentList?.deleteChildRange(namedArg, rangeEnd)
                            }
                            itemText = item.text;
                        } else if (namedArg.firstChild.text == "children") {
                            if (namedArg != null) {
                                if (namedArg.lastChild is DartListLiteralExpression) {
                                    val originalListTextLength = namedArg.textLength
                                    val childRefactoredList = refactor(namedArg.lastChild as DartListLiteralExpression, replaceInRouteName)
                                    classRefs.addAll(childRefactoredList.second)
                                    val startOffset = argsList!!.startOffsetInParent + namedArg.startOffsetInParent
                                    itemText = itemText.replaceRange(IntRange(startOffset, startOffset + originalListTextLength), "children: ${childRefactoredList.first}")
                                }
                            }
                        } else if (namedArg.firstChild.text == "page") {
                            val pageRef = namedArg.lastChild
                            val clazzRef = DartResolveUtil.findReferenceAndComponentTarget(pageRef)
                            if (clazzRef != null) {
                                classRefs.add(RefactableClass(clazzRef, customName))
                            }
                            val startOffset = argsList!!.startOffsetInParent + pageRef.startOffsetInParent;
                            val routeName = Utils.resolveRouteName(pageRef.text, customName, replaceInRouteName)
                            itemText = itemText.replaceRange(IntRange(startOffset, startOffset + pageRef.textLength), "${routeName}.page")

                        }
                    }
                append("$itemText,")
            }
            append("]")
        }.toString()
        return Pair(sb, classRefs)
    }

    class RefactableClass(val classRef: DartComponent, customName: String?)

    private fun addAnnotationIfNeeded(project: Project, clazzRef: DartComponent, customName: String?) {
        if (clazzRef.getMetadataByName("RoutePage") != null) return
        FileDocumentManager.getInstance().getDocument(clazzRef.containingFile.virtualFile)?.apply {
            WriteCommandAction.runWriteCommandAction(project) {
                setReadOnly(false)
                insertString(clazzRef.startOffset, "@RoutePage(${customName ?: ""})\n")
                PsiUtils.getAutoRouteImportOffsetIfNeeded(clazzRef.containingFile)?.let { offset ->
                    insertString(offset, "${Strings.autoRouteImport}\n")
                }
                ReformatCodeProcessor(clazzRef.containingFile, false).run()
                PsiDocumentManager.getInstance(project).commitDocument(this)
            }
        }
    }


}




