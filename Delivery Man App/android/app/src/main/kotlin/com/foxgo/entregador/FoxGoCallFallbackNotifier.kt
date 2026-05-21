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
    private const val DEDUPE_TTL_MS = 8_000L
    private var lastFallbackKey: String? = null
    private var lastFallbackAtMs: Long = 0L

    fun show(context: Context, data: Map<String, Any?>, source: String): Boolean {
        val appContext = context.applicationContext
        return try {
            val key = fallbackKey(data)
            val now = System.currentTimeMillis()
            if (key.isNotBlank() && key == lastFallbackKey && (now - lastFallbackAtMs) < DEDUPE_TTL_MS) {
                Log.i(TAG, "fallback dedupe bloqueado source=$source key=$key")
                return true
            }
            lastFallbackKey = key
            lastFallbackAtMs = now

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

    fun cancel(context: Context, source: String) {
        try {
            val appContext = context.applicationContext
            val manager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(NOTIFICATION_ID)
            Log.i(TAG, "fallback cancelado source=$source")
        } catch (exception: Exception) {
            Log.e(TAG, "falha ao cancelar fallback source=$source", exception)
        }
    }

    private fun buildNotification(context: Context, data: Map<String, Any?>): Notification {
        val orderId = first(data, "orderId", "order_id", "id")
        val callId = first(data, "callId", "call_id").ifBlank { orderId }
        val title = first(data, "title").ifBlank { moduleTitle(data) }
        val origin = first(data, "originName", "storeName", "store_name", "pickupName")
        val destination = first(data, "destinationAddress", "destination_address", "deliveryAddress", "receiverAddress")
        val earning = first(data, "earning", "driverEarningAmount", "driver_earning", "deliveryCharge")
        val distance = first(data, "distance", "totalDistanceKm", "total_distance")
        val payment = paymentLabel(first(data, "paymentMethod", "payment_method"))
        val text = compactText(orderId, earning, distance, payment)
        val bigText = listOf(
            if (earning.isNotBlank()) "Você recebe: $earning" else "",
            if (distance.isNotBlank()) "Distância: $distance" else "",
            if (payment.isNotBlank()) "Pagamento: $payment" else "",
            if (origin.isNotBlank()) "Origem: $origin" else "",
            if (destination.isNotBlank()) "Destino: $destination" else "",
        ).filter { it.isNotBlank() }.joinToString("\n").ifBlank { text }

        val openIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(NewCallOverlayService.EXTRA_OPEN_ORDER_REQUEST, true)
            putExtra(NewCallOverlayService.EXTRA_OVERLAY_ACTION, "onNewCallFallbackOpen")
            if (orderId.isNotEmpty()) putExtra(NewCallOverlayService.EXTRA_ORDER_ID, orderId)
            if (callId.isNotEmpty()) putExtra(NewCallOverlayService.EXTRA_CALL_ID, callId)
            data.forEach { (key, value) -> putExtraValue(key, value) }
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
        Log.i(TAG, "PendingIntent fallback aceitar=4103 recusar=4104 orderId=$orderId callId=$callId title=$title")

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
            .setStyle(Notification.BigTextStyle().bigText(bigText))
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

    private fun fallbackKey(data: Map<String, Any?>): String {
        return first(data, "orderId", "order_id", "id", "callId", "call_id")
    }

    private fun moduleTitle(data: Map<String, Any?>): String {
        val raw = listOf(first(data, "moduleType", "module_type"), first(data, "orderType", "order_type"), first(data, "rawType")).joinToString("|").lowercase()
        return when {
            raw.contains("ride") || raw.contains("taxi") || raw.contains("corrida") -> "Nova corrida"
            raw.contains("parcel") || raw.contains("encomenda") -> "Nova encomenda"
            raw.contains("pharmacy") || raw.contains("farm") -> "Nova entrega de farmácia"
            raw.contains("grocery") || raw.contains("market") || raw.contains("mercado") -> "Nova entrega de mercado"
            else -> "Nova entrega disponível"
        }
    }

    private fun compactText(orderId: String, earning: String, distance: String, payment: String): String {
        val parts = listOf(
            if (orderId.isNotBlank()) "#$orderId" else "",
            if (earning.isNotBlank()) earning else "",
            if (distance.isNotBlank()) distance else "",
            if (payment.isNotBlank()) payment else "",
        ).filter { it.isNotBlank() }
        return parts.joinToString(" • ").ifBlank { "Toque para abrir a nova chamada" }
    }

    private fun paymentLabel(raw: String): String {
        return when (raw) {
            "cash_on_delivery" -> "Dinheiro"
            "wallet" -> "Carteira"
            "offline_payment" -> "Pagamento offline"
            "partial_payment" -> "Pagamento parcial"
            else -> raw
        }
    }

    private fun first(data: Map<String, Any?>, vararg keys: String): String {
        for (key in keys) {
            val value = data[key]?.toString()?.trim().orEmpty()
            if (value.isNotBlank() && value != "null") return value
        }
        return ""
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