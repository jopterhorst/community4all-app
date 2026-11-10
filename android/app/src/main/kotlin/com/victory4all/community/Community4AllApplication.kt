package com.victory4all.community

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

// Creates the channel push notifications arrive in (default_notification_channel_id in AndroidManifest.xml).
// Without it Firebase posts them in its own "Miscellaneous" channel at default importance, which shows no banner.
// A separate file rather than MainActivity.kt, so syncing upstream never conflicts.
class Community4AllApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(PUSH_CHANNEL, "Notifications", NotificationManager.IMPORTANCE_HIGH)
            )
        }
    }

    companion object {
        const val PUSH_CHANNEL = "community4all"
    }
}
