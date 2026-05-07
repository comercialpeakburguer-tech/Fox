package com.foxgo.entregador

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

class FoxGoOnlineService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val republishRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                republishOnlineNotification("watchdog")
                handler.postDelayed(this, REPUBLISH_INTERVAL_MS)
            }
        }
    }
    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Serviço online criado")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_REPUBLISH -> {
                Log.i(TAG, "deleteIntent/republish recebido; isRunning=$isRunning")
                if (isRunning) {
                    republishOnlineNotification("delete_intent")
                    START_STICKY
                } else {
                    START_NOT_STICKY
                }
            }
            ACTION_STOP -> {
                Log.i(TAG, "service online parado")
                isRunning = false
                handler.removeCallbacks(republishRunnable)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                START_NOT_STICKY
            }
            else -> {
                try {
                    Log.i(TAG, "service online start solicitado")
                    ensureChannel()
                    startForeground(NOTIFICATION_ID, buildOnlineNotification())
                    isRunning = true
                    handler.removeCallbacks(republishRunnable)
                    handler.postDelayed(republishRunnable, REPUBLISH_INTERVAL_MS)
                    Log.i(TAG, "service online iniciado com sucesso; notificationId=$NOTIFICATION_ID channel=$CHANNEL_ID")
                    START_STICKY
                } catch (securityException: SecurityException) {
                    isRunning = false
                    Log.e(TAG, "erro ao iniciar service online", securityException)
                    stopSelf()
                    START_NOT_STICKY
                } catch (exception: Exception) {
                    isRunning = false
                    Log.e(TAG, "erro ao iniciar service online", exception)
                    stopSelf()
                    START_NOT_STICKY
                }
            }
        }
    }

    override fun onDestroy() {
        Log.i(TAG, "service online parado")
        handler.removeCallbacks(republishRunnable)
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildOnlineNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            4101,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )

        val deleteIntent = PendingIntent.getService(
            this,
            4102,
            Intent(this, FoxGoOnlineService::class.java).apply { action = ACTION_REPUBLISH },
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Fox GO online")
                .setContentText("Fox GO online — aguardando chamadas")
                .setContentIntent(pendingIntent)
                .setDeleteIntent(deleteIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(false)
                .setLocalOnly(true)
                .setPriority(Notification.PRIORITY_LOW)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Fox GO online")
                .setContentText("Fox GO online — aguardando chamadas")
                .setContentIntent(pendingIntent)
                .setDeleteIntent(deleteIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(false)
                .setLocalOnly(true)
                .setPriority(Notification.PRIORITY_LOW)
                .build()
        }
    }

    private fun republishOnlineNotification(reason: String) {
        try {
            ensureChannel()
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, buildOnlineNotification())
            Log.i(TAG, "notificação online republicada reason=$reason notificationId=$NOTIFICATION_ID")
        } catch (exception: Exception) {
            Log.e(TAG, "erro ao republicar notificação online reason=$reason", exception)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Status online", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Notificação permanente do entregador online"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                },
            )
        }
    }

    private fun immutableFlag(): Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

    companion object {
        private const val TAG = "FoxGoOnlineService"
        const val CHANNEL_ID = "foxgo_online_service"
        private const val NOTIFICATION_ID = 4100
        private const val ACTION_START = "com.foxgo.entregador.online.START"
        private const val ACTION_STOP = "com.foxgo.entregador.online.STOP"
        private const val ACTION_REPUBLISH = "com.foxgo.entregador.online.REPUBLISH"
        private const val REPUBLISH_INTERVAL_MS = 30_000L

        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context): Boolean {
            Log.i(TAG, "service online start solicitado")
            return try {
                val intent = Intent(context, FoxGoOnlineService::class.java).apply { action = ACTION_START }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (securityException: SecurityException) {
                isRunning = false
                Log.e(TAG, "erro ao iniciar service online", securityException)
                false
            } catch (exception: Exception) {
                isRunning = false
                Log.e(TAG, "erro ao iniciar service online", exception)
                false
            }
        }

        fun stop(context: Context): Boolean {
            return try {
                val intent = Intent(context, FoxGoOnlineService::class.java).apply { action = ACTION_STOP }
                context.startService(intent)
                true
            } catch (exception: Exception) {
                isRunning = false
                Log.e(TAG, "erro ao parar service online", exception)
                false
            }
        }
    }
}
