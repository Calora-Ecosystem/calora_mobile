package ai.calora.steps

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.health.connect.client.PermissionController
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class CaloraStepsPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private lateinit var context: Context
    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var activity: Activity? = null
    private var scope: CoroutineScope? = null
    private var listener: ((Map<String, Any?>) -> Unit)? = null
    private var permissionLauncher: ActivityResultLauncher<Set<String>>? = null
    private var pendingPermission: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        StepEngine.init(context)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        methods = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also { it.setMethodCallHandler(this) }
        events = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    detachListener()
                    val forward: (Map<String, Any?>) -> Unit = { snapshot -> sink.success(snapshot) }
                    listener = forward
                    StepEngine.addListener(forward)
                }

                override fun onCancel(arguments: Any?) = detachListener()
            })
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        detachListener()
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        methods = null
        events = null
        scope?.cancel()
        scope = null
    }

    private fun detachListener() {
        listener?.let(StepEngine::removeListener)
        listener = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() = releaseActivity()

    override fun onDetachedFromActivity() = releaseActivity()

    private fun releaseActivity() {
        permissionLauncher?.unregister()
        permissionLauncher = null
        pendingPermission?.success(mapOf("result" to "interrupted"))
        pendingPermission = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                StepEngine.startTracking()
                result.success(StepEngine.snapshot())
            }

            "stop" -> {
                StepEngine.stopTracking()
                result.success(null)
            }

            "ensureRunning" -> result.success(StepEngine.isEnabled && StepEngine.ensureService())

            "configure" -> {
                StepEngine.configure(
                    goal = call.argument<Number>("goal")?.toInt(),
                    weightKg = call.argument<Number>("weightKg")?.toDouble(),
                    kcalPerStep = call.argument<Number>("kcalPerStep")?.toDouble(),
                    labels = call.argument<Map<String, Any?>>("labels")?.let(::labelsOf),
                )
                result.success(null)
            }

            "snapshot" -> result.success(StepEngine.snapshot())

            "refresh" -> StepEngine.refresh(force = call.argument<Boolean>("force") ?: false) {
                result.success(StepEngine.snapshot())
            }

            "history" -> {
                val days = (call.argument<Number>("days")?.toInt() ?: 30).coerceIn(1, 35)
                if (call.argument<Boolean>("refresh") == true) {
                    StepEngine.refreshHistory(force = call.argument<Boolean>("force") ?: false) {
                        result.success(StepEngine.history(days))
                    }
                } else {
                    result.success(StepEngine.history(days))
                }
            }

            "status" -> launch(result) { StepEngine.status() }

            "connectHealthConnect" -> connectHealthConnect(result)

            "openHealthConnect" -> {
                val hc = StepEngine.healthConnect
                val intent = hc.settingsIntent() ?: hc.manageDataIntent()
                result.success(intent != null && DeviceCare.start(host(), intent))
            }

            "installHealthConnect" -> result.success(DeviceCare.start(host(), StepEngine.healthConnect.storeIntent()))

            "openTracker" -> {
                val packageName = call.argument<String>("package")
                val intent = packageName?.let { TrackerApps.launchIntent(context, it) }
                result.success(intent != null && DeviceCare.start(host(), intent))
            }

            "requestIgnoreBatteryOptimizations" -> result.success(DeviceCare.requestIgnoreBatteryOptimizations(host()))

            "openAutoStart" -> result.success(DeviceCare.openAutoStart(host()))

            "openAppSettings" -> result.success(DeviceCare.openAppDetails(host()))

            "openNotificationSettings" -> result.success(DeviceCare.openNotificationSettings(host()))

            else -> result.notImplemented()
        }
    }

    private fun host(): Context = activity ?: context

    private fun labelsOf(map: Map<String, Any?>): NotificationLabels {
        val fallback = NotificationLabels()
        fun text(key: String, default: String) = (map[key] as? String)?.takeIf { it.isNotBlank() } ?: default
        return NotificationLabels(
            channel = text("channel", fallback.channel),
            title = text("title", fallback.title),
            goal = text("goal", fallback.goal),
            kcal = text("kcal", fallback.kcal),
            goalReached = text("goalReached", fallback.goalReached),
            locale = text("locale", fallback.locale),
        )
    }

    private fun launch(result: MethodChannel.Result, block: suspend () -> Any?) {
        val active = scope
        if (active == null) {
            result.error("detached", "Plugin detached", null)
            return
        }
        active.launch {
            try {
                result.success(block())
            } catch (t: Throwable) {
                Log.w(TAG, "Call failed: ${t.message}")
                result.error("failed", t.message, null)
            }
        }
    }

    private fun connectHealthConnect(result: MethodChannel.Result) {
        val hc = StepEngine.healthConnect
        when (hc.availability()) {
            HealthConnectAvailability.UNSUPPORTED -> {
                result.success(mapOf("result" to "unsupported"))
                return
            }

            HealthConnectAvailability.NOT_INSTALLED, HealthConnectAvailability.UPDATE_REQUIRED -> {
                val opened = DeviceCare.start(host(), hc.storeIntent())
                result.success(mapOf("result" to if (opened) "store_opened" else "unsupported"))
                return
            }

            HealthConnectAvailability.AVAILABLE -> Unit
        }

        val component = activity as? ComponentActivity
        if (component == null) {
            result.success(mapOf("result" to "no_activity"))
            return
        }
        if (pendingPermission != null) {
            result.success(mapOf("result" to "busy"))
            return
        }

        val active = scope
        if (active == null) {
            result.success(mapOf("result" to "no_activity"))
            return
        }
        pendingPermission = result
        active.launch {
            val required = hc.requiredPermissions()
            val granted = hc.grantedPermissions()
            if (granted.containsAll(required)) {
                pendingPermission = null
                StepEngine.refreshHistory(force = true)
                StepEngine.refresh(force = true)
                result.success(mapOf("result" to "connected"))
                return@launch
            }
            requestPermissions(component, required)
        }
    }

    private fun requestPermissions(component: ComponentActivity, permissions: Set<String>) {
        permissionLauncher?.unregister()
        val launcher = component.activityResultRegistry.register(
            PERMISSION_KEY,
            PermissionController.createRequestPermissionResultContract(),
        ) { granted ->
            val reply = pendingPermission
            pendingPermission = null
            permissionLauncher?.unregister()
            permissionLauncher = null
            val connected = HealthConnectSource.READ_STEPS in granted
            if (connected) {
                StepEngine.refreshHistory(force = true)
                StepEngine.refresh(force = true)
            }
            reply?.success(mapOf("result" to if (connected) "connected" else "denied"))
        }
        permissionLauncher = launcher
        try {
            launcher.launch(permissions)
        } catch (t: Throwable) {
            Log.w(TAG, "Health Connect permission launch failed: ${t.message}")
            launcher.unregister()
            permissionLauncher = null
            pendingPermission?.success(mapOf("result" to "denied"))
            pendingPermission = null
        }
    }

    companion object {
        private const val TAG = "CaloraSteps.Plugin"
        private const val METHOD_CHANNEL = "calora_steps"
        private const val EVENT_CHANNEL = "calora_steps/updates"
        private const val PERMISSION_KEY = "calora_steps_health_connect"
    }
}
