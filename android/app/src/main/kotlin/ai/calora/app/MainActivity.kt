package ai.calora.app

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
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
                        val mode = call.argument<String>("mode") ?: StepsFgService.MODE_SENSOR

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_START
                            putExtra(StepsFgService.EXTRA_GOAL, goal)
                            putExtra(StepsFgService.EXTRA_WEIGHT_KG, weight)
                            putExtra(StepsFgService.EXTRA_MODE, mode)
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
                        val mode = call.argument<String>("mode") ?: StepsFgService.MODE_MIRROR

                        val i = Intent(this, StepsFgService::class.java).apply {
                            action = StepsFgService.ACTION_SYNC
                            putExtra(StepsFgService.EXTRA_STEPS, steps)
                            putExtra(StepsFgService.EXTRA_WEIGHT_KG, weight)
                            putExtra(StepsFgService.EXTRA_MODE, mode)
                        }
                        startService(i)
                        result.success(null)
                    }

                    "getNativeSteps" -> {
                        // Read the value the foreground service persisted —
                        // this keeps advancing while the app is closed, so
                        // it's how Flutter recovers steps counted in the
                        // background after the user reopens the app.
                        result.success(readNativeStepsForToday())
                    }

                    "getStepsHistory" -> {
                        // Return the map of persisted daily totals (last
                        // 30 days). Used by Flutter on resume/start to
                        // hydrate the Hive ledger with any days that
                        // passed while the app was closed.
                        result.success(readStepsHistory())
                    }

                    "ensureRunning" -> {
                        // Idempotent nudge — starts StepsFgService if not
                        // already running. Send-no-action → handleAutoRestart
                        // path re-asserts foreground without disturbing the
                        // sensor baseline.
                        try {
                            val i = Intent(this, StepsFgService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                ContextCompat.startForegroundService(this, i)
                            } else {
                                startService(i)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.w("MainActivity", "ensureRunning failed: ${e.message}")
                            result.success(false)
                        }
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

                    "openHealthConnectAppPermissions" -> {
                        val pkg = call.argument<String>("package")
                        result.success(openHealthConnectAppPermissions(pkg))
                    }

                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }

                    "openAutoStartSettings" -> {
                        result.success(openAutoStartSettings())
                    }

                    "openAppDetailsSettings" -> {
                        openAppDetailsSettings()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /// Mirrors StepsFgService's persistence: returns the displayed step
    /// total if it belongs to the current day, otherwise 0.
    private fun readNativeStepsForToday(): Int {
        return try {
            val prefs = getSharedPreferences("calora_steps_native", MODE_PRIVATE)
            val cal = java.util.Calendar.getInstance()
            val today = cal.get(java.util.Calendar.YEAR) * 10000 +
                    (cal.get(java.util.Calendar.MONTH) + 1) * 100 +
                    cal.get(java.util.Calendar.DAY_OF_MONTH)
            if (prefs.getInt("day_yyyymmdd", 0) != today) 0
            else prefs.getInt("shown_steps", 0).coerceAtLeast(0)
        } catch (e: Exception) {
            Log.e("MainActivity", "readNativeStepsForToday failed", e)
            0
        }
    }

    /// Returns the last-30-day historical totals the FG service wrote to
    /// SharedPrefs (`hist_yyyymmdd = final_shown_steps`), plus today's
    /// in-progress total under today's ISO key. Keys are `yyyy-MM-dd`
    /// so Dart can parse them directly with `DateTime.parse`.
    private fun readStepsHistory(): Map<String, Int> {
        return try {
            val prefs = getSharedPreferences("calora_steps_native", MODE_PRIVATE)
            val out = LinkedHashMap<String, Int>()

            for ((rawKey, rawValue) in prefs.all) {
                if (rawKey == null || !rawKey.startsWith("hist_")) continue
                val dayInt = rawKey.substring(5) // "hist_".length
                if (dayInt.length != 8) continue
                val steps = when (rawValue) {
                    is Int -> rawValue
                    is Long -> rawValue.toInt()
                    else -> continue
                }
                if (steps <= 0) continue
                val iso = "${dayInt.substring(0, 4)}-${dayInt.substring(4, 6)}-${dayInt.substring(6, 8)}"
                out[iso] = steps
            }

            // Include today's in-progress total (only if KEY_DAY == today).
            val cal = java.util.Calendar.getInstance()
            val todayInt = cal.get(java.util.Calendar.YEAR) * 10000 +
                (cal.get(java.util.Calendar.MONTH) + 1) * 100 +
                cal.get(java.util.Calendar.DAY_OF_MONTH)
            if (prefs.getInt("day_yyyymmdd", 0) == todayInt) {
                val today = "%04d-%02d-%02d".format(
                    cal.get(java.util.Calendar.YEAR),
                    cal.get(java.util.Calendar.MONTH) + 1,
                    cal.get(java.util.Calendar.DAY_OF_MONTH),
                )
                val todaySteps = prefs.getInt("shown_steps", 0).coerceAtLeast(0)
                if (todaySteps > 0) out[today] = todaySteps
            }
            out
        } catch (e: Exception) {
            Log.e("MainActivity", "readStepsHistory failed", e)
            emptyMap()
        }
    }

    // ── Health Connect: manage another app's data permissions ──────────

    /// Opens the Health Connect screen where the user manages what a
    /// given app (Samsung Health / Google Fit) may read/write — i.e.
    /// where they can flip "Allow all" so the tracker writes Steps into
    /// Health Connect. Falls back to Health Connect's main settings.
    private fun openHealthConnectAppPermissions(targetPackage: String?): Boolean {
        if (!targetPackage.isNullOrEmpty()) {
            try {
                val intent = Intent("androidx.health.ACTION_MANAGE_HEALTH_PERMISSIONS").apply {
                    putExtra(Intent.EXTRA_PACKAGE_NAME, targetPackage)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            } catch (e: Exception) {
                Log.w("MainActivity", "MANAGE_HEALTH_PERMISSIONS failed: ${e.message}")
            }
        }
        // Fallback: Health Connect home (has the "App permissions" list).
        return try {
            val intent = Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                val launch = packageManager.getLaunchIntentForPackage(HEALTH_CONNECT_PACKAGE)
                if (launch != null) { startActivity(launch); true } else false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "openHealthConnectAppPermissions failed", e)
            false
        }
    }

    // ── Battery optimization / OEM autostart deep links ────────────────

    private fun isIgnoringBatteryOptimizations(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                true
            } else {
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                pm.isIgnoringBatteryOptimizations(packageName)
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "isIgnoringBatteryOptimizations failed: ${e.message}")
            false
        }
    }

    @SuppressLint("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                startActivity(
                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                )
            } else {
                openAppDetailsSettings()
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "requestIgnoreBatteryOptimizations failed: ${e.message}")
            // Fallback to the system battery-optimization list.
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (e2: Exception) {
                openAppDetailsSettings()
            }
        }
    }

    /// Tries known OEM "autostart / background-activity" screens by
    /// vendor. Each is attempted directly (package-visibility makes
    /// resolveActivity unreliable), and any failure just moves to the
    /// next. Falls back to this app's details page.
    private fun openAutoStartSettings(): Boolean {
        val components = listOf(
            // Xiaomi / MIUI / POCO / Redmi
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            // Samsung (Device care — never-sleeping apps live here)
            ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"),
            ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity"),
            ComponentName("com.samsung.android.sm_cn", "com.samsung.android.sm.ui.battery.BatteryActivity"),
            // Huawei / Honor
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
            // Oppo / Realme / ColorOS
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
            ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
            // Vivo / iQOO
            ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
            // OnePlus
            ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"),
            // Letv
            ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
        )
        for (cn in components) {
            try {
                startActivity(
                    Intent().apply {
                        component = cn
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                )
                return true
            } catch (_: Exception) {
                // Not this vendor / activity not available — try the next.
            }
        }
        // No vendor screen — at least land the user on the app's settings.
        openAppDetailsSettings()
        return false
    }

    private fun openAppDetailsSettings() {
        try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            )
        } catch (e: Exception) {
            Log.e("MainActivity", "openAppDetailsSettings failed", e)
        }
    }

    private fun openHealthConnectSettings(result: MethodChannel.Result) {
        try {
            // Try opening Health Connect settings.
            val intent = Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
                return
            }

            // Try launching the Health Connect app directly.
            val launchIntent = packageManager.getLaunchIntentForPackage(HEALTH_CONNECT_PACKAGE)
            if (launchIntent != null) {
                startActivity(launchIntent)
                result.success(true)
            } else {
                // Health Connect isn't installed — do NOT redirect to the
                // Play Store. The app falls back to the native sensor.
                Log.i("MainActivity", "Health Connect not installed; skipping (no Play Store redirect)")
                result.success(false)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error opening Health Connect", e)
            result.success(false)
        }
    }
}
