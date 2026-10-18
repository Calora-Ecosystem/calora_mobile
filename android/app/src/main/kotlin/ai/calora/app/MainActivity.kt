package ai.calora.app

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        flutterEngine?.activityControlSurface?.onNewIntent(intent)
    }
}
