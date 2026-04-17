package ai.calora.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "ai.calora.app/steps_native_fgs"
    private val HEALTH_CONNECT_PACKAGE = "com.google.android.apps.healthdata"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        flutterEngine?.activityControlSurface?.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        Log.d("MainActivity", "Method 'start' called from Flutter")
                        val goal = call.argument<Int>("goal") ?: 10000
                        val weight = (call.argument<Double>("weight_kg") ?: 70.0).toFloat()

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_START
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
                            putExtra(StepsFgService.EXTRA_WEIGHT_KG, weight)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            ContextCompat.startForegroundService(this, i)
                        } else {
                            startService(i)
                        }
                        result.success(true)
                    }

                    "update_goal" -> {
                        val goal = call.argument<Int>("goal") ?: 10000
                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_UPDATE_GOAL
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
                        }
                        startService(i)
                        result.success(null)
                    }

                    "sync" -> {
                        val steps = call.argument<Int>("steps") ?: 0
                        val weight = (call.argument<Double>("weight_kg") ?: 70.0).toFloat()

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_SYNC
                            putExtra(StepsFgService.EXTRA_STEPS, steps)
                            putExtra(StepsFgService.EXTRA_WEIGHT_KG, weight)
                        }
                        startService(i)
                        result.success(null)
                    }

                    "stop" -> {
                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_STOP
                        }
                        startService(i)
                        result.success(null)
                    }

                    "openHealthConnectSettings" -> {
                        openHealthConnectSettings(result)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun openHealthConnectSettings(result: MethodChannel.Result) {
        try {
            // Try opening Health Connect settings
            val intent = Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                // Try specific package intent if action fails
                val launchIntent = packageManager.getLaunchIntentForPackage(HEALTH_CONNECT_PACKAGE)
                if (launchIntent != null) {
                    startActivity(launchIntent)
                    result.success(true)
                } else {
                    // Fallback: Open Play Store
                    openPlayStore(HEALTH_CONNECT_PACKAGE)
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error opening Health Connect", e)
            openPlayStore(HEALTH_CONNECT_PACKAGE)
            result.error("UNAVAILABLE", "Could not open Health Connect settings", e.message)
        }
    }

    private fun openPlayStore(packageName: String) {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")))
        } catch (e: Exception) {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")))
        }
    }
}
