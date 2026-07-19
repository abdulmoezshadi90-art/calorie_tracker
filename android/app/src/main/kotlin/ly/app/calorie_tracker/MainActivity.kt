package ly.app.calorie_tracker

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Opens the user's mail app prefilled (feedback path, issue #17).
    // A MethodChannel instead of the url_launcher package: the tiny
    // dependency footprint is deliberate (CLAUDE.md design decision 6).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ly.app.calorie_tracker/mail"
        ).setMethodCallHandler { call, result ->
            if (call.method == "openMail") {
                try {
                    val intent = Intent(Intent.ACTION_SENDTO).apply {
                        data = Uri.parse("mailto:")
                        putExtra(Intent.EXTRA_EMAIL, arrayOf(call.argument<String>("to")))
                        putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject"))
                        putExtra(Intent.EXTRA_TEXT, call.argument<String>("body"))
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false) // no mail app → Dart falls back to clipboard
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
