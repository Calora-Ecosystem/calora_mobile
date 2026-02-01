package ai.calora.app

import android.content.Intent
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
                        val steps = call.argument<Int>("steps") ?: 0
                        val goal = call.argument<Int>("goal") ?: 8000

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_START
                            putExtra(StepsFgService.EXTRA_STEPS, steps)
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
                        }
                        startService(i)
                        result.success(true)
                    }

                    "update" -> {
                        val steps = call.argument<Int>("steps") ?: 0
                        val goal = call.argument<Int>("goal") ?: 8000

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_UPDATE
                            putExtra(StepsFgService.EXTRA_STEPS, steps)
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
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
