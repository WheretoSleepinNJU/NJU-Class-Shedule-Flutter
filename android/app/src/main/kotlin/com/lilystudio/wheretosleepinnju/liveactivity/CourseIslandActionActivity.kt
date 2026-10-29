package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import java.util.UUID

/** OEM serialized action URIs enter through an Activity, authenticated per installation. */
class CourseIslandActionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val action = intent.action
            if (intent.getStringExtra("token") != null && intent.getStringExtra("token") ==
                CourseActivityStore.prefs(this).getString("actionToken", null) &&
                action in setOf(CourseActivityReceiver.ARRIVED, CourseActivityReceiver.DISMISS)) {
                intent.getStringExtra("activityId")?.let {
                    CourseActivityEngine.dismiss(this, it, action == CourseActivityReceiver.ARRIVED)
                }
            }
        } finally { finish() }
    }
    companion object {
        @Synchronized private fun token(context: Context): String {
            val prefs = CourseActivityStore.prefs(context)
            return prefs.getString("actionToken", null) ?: UUID.randomUUID().toString().also {
                check(prefs.edit().putString("actionToken", it).commit())
            }
        }
        fun intent(context: Context, item: CourseActivity, action: String) = Intent(context, CourseIslandActionActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            .setAction(action).putExtra("token", token(context)).putExtra("activityId", item.id)
            .setData(android.net.Uri.Builder().scheme("ncs-island").authority("action").appendPath(item.id).appendPath(action).build())
    }
}
