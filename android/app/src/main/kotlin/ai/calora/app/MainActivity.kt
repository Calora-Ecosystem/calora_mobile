package ai.calora.app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "ai.calora.app/steps_native_fgs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val goal = call.argument<Int>("goal") ?: 8000

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_START
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(i)
                        else startService(i)

                        result.success(true)
                    }

                    "update_goal" -> {
                        val goal = call.argument<Int>("goal") ?: 8000
                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_UPDATE_GOAL
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
                        }
                        startService(i)
                        result.success(true)
                    }

                    "sync" -> {
                        val steps = call.argument<Int>("steps") ?: 0
                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_SYNC
                            putExtra(StepsFgService.EXTRA_STEPS, steps)
                        }
                        startService(i)
                        result.success(true)
                    }

                    "stop" -> {
                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_STOP
                        }
                        startService(i)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
