package ai.calora.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle

class HealthPrivacyActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(PRIVACY_POLICY_URL)))
        } catch (_: Exception) {
            packageManager.getLaunchIntentForPackage(packageName)?.let(::startActivity)
        }
        finish()
    }

    private companion object {
        const val PRIVACY_POLICY_URL = "https://calora.uz/privacy-policy"
    }
}
