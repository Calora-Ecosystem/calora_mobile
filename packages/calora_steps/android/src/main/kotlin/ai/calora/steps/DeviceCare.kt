package ai.calora.steps

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings

object DeviceCare {

    private val autoStartScreens = listOf(
        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
        ComponentName("com.hihonor.systemmanager", "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
        ComponentName("com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
        ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
        ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"),
        ComponentName("com.transsion.phonemaster", "com.cyin.himgr.autostart.AutoStartActivity"),
        ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity"),
        ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
    )

    private val samsungBatteryScreens = listOf(
        ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity"),
        ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"),
        ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity"),
    )

    fun isIgnoringBatteryOptimizations(context: Context): Boolean = try {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        power.isIgnoringBatteryOptimizations(context.packageName)
    } catch (t: Throwable) {
        false
    }

    @SuppressLint("BatteryLife")
    fun requestIgnoreBatteryOptimizations(context: Context): Boolean {
        val direct = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:${context.packageName}"))
        return start(context, direct) ||
            start(context, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) ||
            openAppDetails(context)
    }

    private fun candidates(): List<ComponentName> =
        if (isSamsung()) samsungBatteryScreens + autoStartScreens else autoStartScreens

    fun hasAutoStartScreen(context: Context): Boolean {
        val pm = context.packageManager
        return candidates().any { resolves(pm, Intent().setComponent(it)) }
    }

    fun openAutoStart(context: Context): Boolean {
        val pm = context.packageManager
        val ordered = candidates().sortedByDescending { resolves(pm, Intent().setComponent(it)) }
        return ordered.any { start(context, Intent().setComponent(it)) } || openAppDetails(context)
    }

    fun openAppDetails(context: Context): Boolean =
        start(context, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")))

    fun openNotificationSettings(context: Context): Boolean {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        return start(context, intent) || openAppDetails(context)
    }

    fun start(context: Context, intent: Intent): Boolean = try {
        if (context !is android.app.Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        true
    } catch (t: Throwable) {
        false
    }

    private fun resolves(pm: PackageManager, intent: Intent): Boolean = try {
        pm.resolveActivity(intent, 0) != null
    } catch (t: Throwable) {
        false
    }

    private fun isSamsung(): Boolean = android.os.Build.MANUFACTURER.equals("samsung", ignoreCase = true)
}
