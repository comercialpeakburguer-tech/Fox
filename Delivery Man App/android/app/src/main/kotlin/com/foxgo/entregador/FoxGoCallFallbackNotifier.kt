package com.foxgo.entregador

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log

object FoxGoCallFallbackNotifier {
    private const val TAG = "FoxGoCallFallback"
    private const val CHANNEL_ID = "foxgo_call_fallback_v2"
    private const val NOTIFICATION_ID = 4102

    fun show(context: Context, data: Map<String, Any?>, source: String): Boolean {
        val appContext = context.applicationContext
        return try {
            ensureChannel(appContext)
            val notification = buildNotification(appContext, data)
            val manager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, notification)
            Log.i(TAG, "fallback emitido source=$source keys=${data.keys} type=${data["type"]} orderId=${data["orderId"]} callId=${data["callId"]}")
            true
        } catch (exception: Exception) {
            Log.e(TAG, "fallback falhou source=$source orderId=${data["orderId"]} callId=${data["callId"]}", exception)
            false
        }
    }

    private fun buildNotification(context: Context, data: Map<String, Any?>): Notification {
        val orderId = data["orderId"]?.toString().orEmpty()
        val callId = data["callId"]?.toString().orEmpty()
        val title = data["title"]?.toString()?.takeIf { it.isNotBlank() } ?: "Nova entrega disponível"
        val text = if (orderId.isNotEmpty()) "Toque para abrir o pedido #$orderId" else "Toque para abrir a nova chamada"
        val openIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(NewCallOverlayService.EXTRA_OPEN_ORDER_REQUEST, true)
            putExtra(NewCallOverlayService.EXTRA_OVERLAY_ACTION, "onNewCallFallbackOpen")
            if (orderId.isNotEmpty()) putExtra(NewCallOverlayService.EXTRA_ORDER_ID, orderId)
            if (callId.isNotEmpty()) putExtra(NewCallOverlayService.EXTRA_CALL_ID, callId)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            4102,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )

        val acceptIntent = serviceActionIntent(context, NewCallOverlayService.ACTION_ACCEPT, "onNewCallAccept", data)
        val rejectIntent = serviceActionIntent(context, NewCallOverlayService.ACTION_REJECT, "onNewCallReject", data)
        val acceptPendingIntent = PendingIntent.getService(
            context,
            4103,
            acceptIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
        val rejectPendingIntent = PendingIntent.getService(
            context,
            4104,
            rejectIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
        Log.i(TAG, "PendingIntent fallback aceitar=4103 recusar=4104 orderId=$orderId callId=$callId")

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        return builder
            .setSmallIcon(R.drawable.notification_icon)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_MAX)
            .setCategory(Notification.CATEGORY_CALL)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(false)
            .setFullScreenIntent(pendingIntent, true)
            .setSound(callSoundUri(context))
            .setVibrate(longArrayOf(0, 500, 250, 500))
            .addAction(R.drawable.notification_icon, "Aceitar", acceptPendingIntent)
            .addAction(R.drawable.notification_icon, "Recusar", rejectPendingIntent)
            .build()
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(CHANNEL_ID, "Fox GO chamadas", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Fallback heads-up para novas chamadas de entrega"
            enableVibration(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(callSoundUri(context), AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
        }
        manager.createNotificationChannel(channel)
    }

    private fun serviceActionIntent(context: Context, serviceAction: String, overlayAction: String, data: Map<String, Any?>): Intent {
        return Intent(context, NewCallOverlayService::class.java).apply {
            action = serviceAction
            putExtra(NewCallOverlayService.EXTRA_OPEN_ORDER_REQUEST, true)
            putExtra(NewCallOverlayService.EXTRA_OVERLAY_ACTION, overlayAction)
            data.forEach { (key, value) -> putExtraValue(key, value) }
        }
    }

    private fun Intent.putExtraValue(key: String, value: Any?) {
        when (value) {
            null -> return
            is String -> putExtra(key, value)
            is Boolean -> putExtra(key, value)
            is Int -> putExtra(key, value)
            is Long -> putExtra(key, value)
            is Double -> putExtra(key, value)
            is Float -> putExtra(key, value)
            else -> putExtra(key, value.toString())
        }
    }

    private fun callSoundUri(context: Context): Uri = Uri.parse("android.resource://${context.packageName}/${R.raw.notification}")

    private fun immutableFlag(): Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
}
