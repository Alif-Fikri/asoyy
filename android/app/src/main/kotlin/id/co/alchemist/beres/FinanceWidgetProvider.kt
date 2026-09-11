package id.co.alchemist.beres

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FinanceWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val ACTION_TOGGLE_VISIBILITY =
            "id.co.alchemist.beres.action.TOGGLE_BALANCE_VISIBILITY"
        private const val PREFS_NAME = "finance_widget_prefs"
        private const val KEY_BALANCE_HIDDEN = "balance_hidden"
        private const val MASK = "••••••"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            renderWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE_VISIBILITY) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val hidden = prefs.getBoolean(KEY_BALANCE_HIDDEN, false)
            prefs.edit().putBoolean(KEY_BALANCE_HIDDEN, !hidden).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            val componentName = android.content.ComponentName(context, FinanceWidgetProvider::class.java)
            appWidgetManager.getAppWidgetIds(componentName).forEach { widgetId ->
                renderWidget(context, appWidgetManager, widgetId, widgetData)
            }
            return
        }
        super.onReceive(context, intent)
    }

    private fun renderWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hidden = prefs.getBoolean(KEY_BALANCE_HIDDEN, false)

        val views = RemoteViews(context.packageName, R.layout.finance_widget_layout).apply {
            setTextViewText(
                R.id.widget_balance,
                if (hidden) MASK else widgetData.getString("balance", "Rp 0"),
            )
            setTextViewText(
                R.id.widget_today_expense,
                widgetData.getString("today_expense", "Rp 0"),
            )
            setImageViewResource(
                R.id.widget_toggle_visibility,
                if (hidden) R.drawable.ic_eye_off else R.drawable.ic_eye,
            )

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            val toggleIntent = Intent(context, FinanceWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE_VISIBILITY
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_toggle_visibility, togglePendingIntent)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
