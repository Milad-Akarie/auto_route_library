package come.autoroute.helper.autoroutehelper.models

import com.jetbrains.lang.dart.psi.DartComponent
import com.jetbrains.lang.dart.psi.DartListLiteralExpression

class RefactorResult(val text: String, val classRefs: List<RefactableClass>, val listRefs: List<DartListLiteralExpression>)
class RefactableClass(val classRef: DartComponent, val customName: String?, val deferredLoading: String?, val returnType: String?)
