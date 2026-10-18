package ai.calora.steps

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

data class TrackerApp(val id: String, val name: String, val packages: List<String>)

data class InstalledTracker(val app: TrackerApp, val packageName: String)

object TrackerApps {

    val known: List<TrackerApp> = listOf(
        TrackerApp("samsung_health", "Samsung Health", listOf("com.sec.android.app.shealth")),
        TrackerApp("google_fit", "Google Fit", listOf("com.google.android.apps.fitness")),
        TrackerApp("fitbit", "Fitbit", listOf("com.fitbit.FitbitMobile")),
        TrackerApp("mi_fitness", "Mi Fitness", listOf("com.xiaomi.wearable", "com.mi.health")),
        TrackerApp("zepp_life", "Zepp Life", listOf("com.xiaomi.hm.health")),
        TrackerApp("zepp", "Zepp", listOf("com.huami.watch.hmwatchmanager")),
        TrackerApp("garmin", "Garmin Connect", listOf("com.garmin.android.apps.connectmobile")),
        TrackerApp("huawei_health", "Huawei Health", listOf("com.huawei.health")),
        TrackerApp("honor_health", "Honor Health", listOf("com.hihonor.health")),
        TrackerApp("ohealth", "OHealth", listOf("com.heytap.health")),
        TrackerApp("oura", "Oura", listOf("com.ouraring.oura")),
        TrackerApp("withings", "Withings", listOf("com.withings.wiscale2")),
        TrackerApp("polar", "Polar Flow", listOf("fi.polar.polarflow")),
        TrackerApp("suunto", "Suunto", listOf("com.stt.android.suunto")),
        TrackerApp("coros", "COROS", listOf("com.coros.coros")),
    )

    fun installed(context: Context): List<InstalledTracker> {
        val pm = context.packageManager
        return known.mapNotNull { app ->
            app.packages.firstOrNull { isInstalled(pm, it) }?.let { InstalledTracker(app, it) }
        }
    }

    fun byPackage(packageName: String): TrackerApp? = known.firstOrNull { packageName in it.packages }

    fun launchIntent(context: Context, packageName: String): Intent? =
        context.packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

    private fun isInstalled(pm: PackageManager, packageName: String): Boolean = try {
        pm.getApplicationInfo(packageName, 0).enabled
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}
