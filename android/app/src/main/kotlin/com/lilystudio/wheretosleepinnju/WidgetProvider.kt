package com.lilystudio.wheretosleepinnju;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import android.widget.Toast;
//import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

const val TOAST_ACTION = "com.lilystudio.wheretosleepinnju.TOAST_ACTION"
const val EXTRA_ITEM = "com.lilystudio.wheretosleepinnju.EXTRA_ITEM"


class WidgetProvider : HomeWidgetProvider() {
    // Called when the BroadcastReceiver receives an Intent broadcast.
    // Checks to see whether the intent's action is TOAST_ACTION. If it is, the app widget
    // displays a Toast message for the current item.
    override fun onReceive(context: Context, intent: Intent) {
        val mgr: AppWidgetManager = AppWidgetManager.getInstance(context)
        if (intent.action == TOAST_ACTION) {
            val appWidgetId: Int = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            val viewIndex: Int = intent.getIntExtra(EXTRA_ITEM, 0)
            Toast.makeText(context, "Touched view $viewIndex", Toast.LENGTH_SHORT).show()
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {

        appWidgetIds.forEach { widgetId ->
            // Set up the intent that starts the StackViewService, which will
            // provide the views for this collection.
            val intent = Intent(context, WidgetService::class.java).apply {
                // Add the app widget ID to the intent extras.
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            // Instantiate the RemoteViews object for the app widget layout.
            val rv = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Set up the RemoteViews object to use a RemoteViews adapter.
                // This adapter connects
                // to a RemoteViewsService  through the specified intent.
                // This is how you populate the data.
                setRemoteAdapter(R.id.stack_view, intent)

                // The empty view is displayed when the collection has no items.
                // It should be in the same layout used to instantiate the RemoteViews
                // object above.
                setEmptyView(R.id.stack_view, R.id.empty_view)

//                // Open App on Widget Click
//                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
//                        context,
//                        MainActivity::class.java)
//                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
//
//                // Swap Title Text by calling Dart Code in the Background
//                setTextViewText(R.id.widget_title, widgetData.getString("title", null)
//                        ?: "No Title Set")
//                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
//                        context,
//                        Uri.parse("homeWidgetExample://titleClicked")
//                )
//                setOnClickPendingIntent(R.id.widget_title, backgroundIntent)
//
//                val message = widgetData.getString("message", null)
//                setTextViewText(R.id.widget_message, message
//                        ?: "No Message Set")
//                // Detect App opened via Click inside Flutter
//                val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
//                        context,
//                        MainActivity::class.java,
//                        Uri.parse("homeWidgetExample://message?message=$message"))
//                setOnClickPendingIntent(R.id.widget_message, pendingIntentWithData)
            }
            // This section makes it possible for items to have individualized behavior.
            // It does this by setting up a pending intent template. Individuals items of a
            // collection cannot set up their own pending intents. Instead, the collection as a
            // whole sets up a pending intent template, and the individual items set a fillInIntent
            // to create unique behavior on an item-by-item basis.
            val toastPendingIntent: PendingIntent = Intent(
                context,
                WidgetProvider::class.java
            ).run {
                // Set the action for the intent.
                // When the user touches a particular view, it will have the effect of
                // broadcasting TOAST_ACTION.
                action = TOAST_ACTION
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))

                PendingIntent.getBroadcast(context, 0, this, PendingIntent.FLAG_UPDATE_CURRENT)
            }
            rv.setPendingIntentTemplate(R.id.stack_view, toastPendingIntent)

            appWidgetManager.updateAppWidget(widgetId, rv)
        }
    }
}