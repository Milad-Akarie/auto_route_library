package come.autoroute.helper.autoroutehelper.utils

import com.intellij.openapi.editor.Editor
import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.LocalFileSystem
import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import com.intellij.psi.PsiManager
import com.intellij.psi.PsiWhiteSpace
import com.intellij.psi.util.PsiTreeUtil
import com.intellij.psi.util.parentOfType
import com.intellij.refactoring.suggested.startOffset
import com.jetbrains.lang.dart.psi.*
import com.jetbrains.lang.dart.util.DartResolveUtil
import come.autoroute.helper.autoroutehelper.Strings
import come.autoroute.helper.autoroutehelper.models.RegisteredRoute
import come.autoroute.helper.autoroutehelper.models.RoutePageInfo
import come.autoroute.helper.autoroutehelper.models.RouterConfig
import come.autoroute.helper.autoroutehelper.models.RoutesList
import java.io.File

class PsiUtils {
    companion object {
        private val allowedSuperClasses =
            listOf("StatelessWidget", "StatefulWidget", "ConsumerWidget", "StatefulConsumerWidget")
        fun findPossibleRoutePage(editor: Editor, file: PsiFile?): RoutePageInfo? {
            if (file == null) return null
            val caretOffset = editor.caretModel.offset
            val highLightedElement = file.findElementAt(caretOffset)
            if (highLightedElement is PsiWhiteSpace) return null
            val classElement = highLightedElement?.parentOfType<DartClassDefinition>()
            if (classElement != null) {
                val className = classElement.nameIdentifier ?: return null
                if (!allowedSuperClasses.contains(classElement.superClass?.text)) return null
                val routeAnnotation = classElement.getMetadataByName("RoutePage")
                if (className.textRange.contains(caretOffset) || (routeAnnotation != null && routeAnnotation.textRange.contains(caretOffset))) {
                    val nameArg = PsiTreeUtil.findChildrenOfType(routeAnnotation, DartNamedArgument::class.java).firstOrNull { it.firstChild.text == "name" }
                    var customName = nameArg?.lastChild?.text
                    if (nameArg?.lastChild is DartReferenceExpression) {
                        val resolvedName = DartResolveUtil.findReferenceAndComponentTarget(nameArg.lastChild)?.context?.lastChild
                        customName = resolvedName?.lastChild?.text
                    }
                    return RoutePageInfo(
                            classElement,
                            routeAnnotation,
                            Utils.stripStringQts(customName),
                    );
                }
            }
            return null
        }


        fun getAutoRouteImportOffsetIfNeeded(file: PsiFile?): Int? {
            val imports = PsiTreeUtil.findChildrenOfType(file, DartImportStatement::class.java)
            val hasImport = imports.any { i -> listOf(Strings.autoRouteImport, Strings.autoRouteAnnotationImport).contains(i.text) }
            return if (hasImport) null else imports.firstOrNull()?.startOffset ?: 0
        }

        private fun getRouterClass(project: Project, routerConfig: RouterConfig): DartClass? {
            val virtualFile = LocalFileSystem.getInstance().findFileByIoFile(File(routerConfig.path))
                    ?: return null
            val psiFile = PsiManager.getInstance(project).findFile(virtualFile) ?: return null
            return DartResolveUtil.getClassDeclarations(psiFile).firstOrNull { it.name == routerConfig.routerClassName }
        }

        fun getRoutesList(project: Project, routerConfig: RouterConfig): RoutesList? {
            val routerClass = getRouterClass(project, routerConfig) ?: return null
            val routesList = routerClass.findMemberByName("routes")?.context ?: return null
            val listLiteral =
                PsiTreeUtil.findChildOfType(routesList, DartListLiteralExpression::class.java)
                    ?: return null
            return RoutesList(getRoutes(listLiteral), listLiteral)
        }

        private fun getRoutes(routesList: DartListLiteralExpression): List<RegisteredRoute> {
            val routes = ArrayList<RegisteredRoute>()
            for (item in routesList.elementList.map { it.lastChild }) {
                if (item is DartCallExpression) {
                    val namedArguments =
                        PsiTreeUtil.findChildrenOfType(item, DartNamedArgument::class.java)
                    val nameArg =
                        namedArguments.firstOrNull { it.firstChild.text == "page" } ?: continue
                    var children: RoutesList? = null
                    val childrenArg =
                        namedArguments.firstOrNull { it.firstChild.text == "children" }
                    if (childrenArg != null) {
                        var elementToSearch: PsiElement? = childrenArg
                        if (childrenArg.lastChild is DartReferenceExpression) {
                            elementToSearch = DartResolveUtil.findReferenceAndComponentTarget(childrenArg.lastChild)?.context
                        }
                        val childListLiteral = PsiTreeUtil.findChildOfType(elementToSearch, DartListLiteralExpression::class.java)
                        if (childListLiteral != null) {
                            children = RoutesList(getRoutes(childListLiteral), childListLiteral)
                        }
                    }
                    routes.add(RegisteredRoute(nameArg.lastChild.text.replaceFirst(".page", ""), children, item))
                } else if (item is DartSpreadElement) {
                    val spreadListRef = DartResolveUtil.findReferenceAndComponentTarget(item.lastChild)?.context
                    val spreadListLiteral = PsiTreeUtil.findChildOfType(spreadListRef, DartListLiteralExpression::class.java)
                    if (spreadListLiteral != null) {
                        routes.addAll(getRoutes(spreadListLiteral))
                    }
                }

            }
            return routes
        }

        fun dartClassAt(file: PsiFile, offset: Int): DartClassDefinition? {
            return PsiTreeUtil.findElementOfClassAtOffset(file, offset, DartClassDefinition::class.java, false)
        }
    }
}

