package ai.calora.app

import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ai.calora.app/steps_native_fgs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

                    else -> result.notImplemented()
                }
            }
    }
}
