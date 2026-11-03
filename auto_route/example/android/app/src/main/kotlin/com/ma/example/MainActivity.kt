package com.ma.example

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the integration tests go back through the activity's own back
        // handler, the one Android's back gesture and back key call. An app
        // can't inject a real key press into itself (INJECT_EVENTS).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "auto_route_example/system_back")
            .setMethodCallHandler { call, result ->
                if (call.method != "pressBack") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // From Android 13 the system sends back to Flutter only while
                // Flutter has said it handles back; otherwise Android closes
                // the app itself. Report that instead of closing the app.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !getBackCallbackState()) {
                    result.error("appWouldClose", "Flutter told Android it doesn't handle back", null)
                    return@setMethodCallHandler
                }
                @Suppress("DEPRECATION")
                onBackPressed()
                result.success(null)
            }
    }
}
