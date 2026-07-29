import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple


@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        // Workmanager spins up its own headless Flutter engine for
        // BGAppRefresh runs — plugins (health, path_provider, hive…) must
        // be registered on it too or the Dart sync task can't run.
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }

        // Periodic background step sync. The identifier must match
        // Info.plist (BGTaskSchedulerPermittedIdentifiers) and
        // BackgroundStepsWorker.iosRefreshTask on the Dart side. iOS
        // treats the frequency as a hint — 15 min is the floor and the
        // scheduler decides the real cadence from usage patterns.
        WorkmanagerPlugin.registerPeriodicTask(
            withIdentifier: "com.calora.stepsync",
            frequency: NSNumber(value: 15 * 60)
        )

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}