package com.ma.example

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
                @Suppress("DEPRECATION")
                onBackPressed()
                result.success(null)
            }
    }
}
