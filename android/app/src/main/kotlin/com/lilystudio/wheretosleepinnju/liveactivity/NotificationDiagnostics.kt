package com.lilystudio.wheretosleepinnju.liveactivity

import android.util.Log

/** Diagnostics stay local; expose only the last backend failure to Flutter. */
internal object NotificationDiagnostics {
    fun event(name: String, vararg fields: Pair<String, Any?>) {
        Log.d("CourseIsland", "$name ${fields.joinToString { "${it.first}=${it.second}" }}")
    }
    fun failure(name: String, error: Throwable) { Log.w("CourseIsland", name, error) }
}
