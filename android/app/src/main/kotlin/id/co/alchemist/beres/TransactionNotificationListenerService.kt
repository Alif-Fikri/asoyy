package id.co.alchemist.beres

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class TransactionNotificationListenerService : NotificationListenerService() {

    companion object {
        const val PREFS_NAME = "beres_notification_capture"
        const val KEY_QUEUE = "captured_queue"
        const val MAX_QUEUE_SIZE = 200

        val WATCHED_PACKAGES = setOf(
            "com.bca",
            "com.bca.mybca.omni.android",
            "id.co.bri.brimo",
            "com.gojek.app",
            "id.co.bankbkemobile.digitalbank",
            "id.bmri.livin",
            "src.com.bni",
            "id.dana",
            "ovo.id",
            "com.shopeepay.id",
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (WATCHED_PACKAGES.none { packageName.contains(it, ignoreCase = true) }) return

        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        if (title.isEmpty() && text.isEmpty()) return

        val entry = JSONObject().apply {
            put("packageName", packageName)
            put("title", title)
            put("text", text)
            put("postTime", sbn.postTime)
        }

        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
        val updated = JSONArray()
        val startIndex = if (existing.length() >= MAX_QUEUE_SIZE) existing.length() - MAX_QUEUE_SIZE + 1 else 0
        for (i in startIndex until existing.length()) {
            updated.put(existing.get(i))
        }
        updated.put(entry)

        prefs.edit().putString(KEY_QUEUE, updated.toString()).apply()
    }
}
