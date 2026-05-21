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
import android.os.Looper
import android.media.AudioAttributes
import android.net.Uri
import android.os.IBinder
import android.provider.Settings
import android.util.Log

class NewCallOverlayService : Service() {
    private var overlayManager: NewCallOverlayManager? = null
    private var lastPayload: Map<String, Any?> = emptyMap()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastActionKey: String? = null
    private var lastActionAtMs: Long = 0L
    private var activeCallKey: String? = null

    override fun onCreate() {
        super.onCreate()
        overlayManager = NewCallOverlayManager(applicationContext) { action, data ->
            dispatchCallAction(action, data, source = "overlay")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "NewCallOverlayService.onStartCommand action=${intent?.action} startId=$startId")
        when (intent?.action) {
            ACTION_DISMISS -> {
                dismissOverlay()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_ACCEPT -> {
                dispatchCallAction("onNewCallAccept", payloadFromIntent(intent), source = "notification")
                return START_NOT_STICKY
            }
            ACTION_REJECT -> {
                dispatchCallAction("onNewCallReject", payloadFromIntent(intent), source = "notification")
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> showOrUpdateOverlay(intent)
            else -> showOrUpdateOverlay(intent)
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        dismissOverlay()
        overlayManager = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun showOrUpdateOverlay(intent: Intent?) {
        val payload = payloadFromIntent(intent)
        if (payload.isNotEmpty()) lastPayload = lastPayload + payload
        val payloadKey = callKey(lastPayload)
        if (payloadKey.isNotBlank()) activeCallKey = payloadKey

        val canDraw = Settings.canDrawOverlays(this)
        Log.i(TAG, "Settings.canDrawOverlays=$canDraw no momento da chamada callId=${lastPayload["callId"]} orderId=${lastPayload["orderId"]} key=$payloadKey")
        if (!canDraw) {
            Log.w(FALLBACK_TAG, "overlay indisponível; exibindo fallback heads-up key=$payloadKey")
            emitHeadsUpFallback(lastPayload, "overlay_sem_permissao")
            return
        }

        startForeground(NOTIFICATION_ID, buildServiceNotification(lastPayload))
        val manager = overlayManager
        if (manager == null) {
            isShowing = false
            Log.w(FALLBACK_TAG, "overlayManager nulo; emitindo fallback heads-up callId=${lastPayload["callId"]} orderId=${lastPayload["orderId"]}")
            emitHeadsUpFallback(lastPayload, "overlay_manager_nulo")
            return
        }
        val shown = if (manager.isShowing()) manager.update(lastPayload) else manager.show(lastPayload)
        scheduleOverlayVisibilityCheck(shown, lastPayload)
    }

    private fun scheduleOverlayVisibilityCheck(started: Boolean, data: Map<String, Any?>) {
        mainHandler.removeCallbacksAndMessages(null)
        val keyAtSchedule = callKey(data)
        if (!started) {
            isShowing = false
            Log.w(FALLBACK_TAG, "FoxGoCallFallback emitido porque overlay_nao_visivel callId=${data["callId"]} orderId=${data["orderId"]}")
            emitHeadsUpFallback(data, "overlay_nao_visivel")
            return
        }
        mainHandler.postDelayed({
            if (wasRecentlyActioned(keyAtSchedule)) {
                Log.i(FALLBACK_TAG, "checagem visual ignorada porque ação já foi enviada key=$keyAtSchedule")
                return@postDelayed
            }
            val visible = overlayManager?.isShowing() == true
            isShowing = visible
            Log.i(TAG, "FoxGoOverlayWindow attached após delay $visible callId=${data["callId"]} orderId=${data["orderId"]}")
            if (visible) {
                FoxGoCallFallbackNotifier.cancel(this, source = "overlay_visivel")
                Log.i(FALLBACK_TAG, "FoxGoCallFallback cancelado/evitado porque overlay_visivel callId=${data["callId"]} orderId=${data["orderId"]}")
            } else {
                Log.w(FALLBACK_TAG, "FoxGoCallFallback emitido porque overlay_nao_visivel callId=${data["callId"]} orderId=${data["orderId"]}")
                emitHeadsUpFallback(data, "overlay_nao_visivel")
            }
        }, OVERLAY_CONFIRMATION_DELAY_MS)
    }

    private fun emitHeadsUpFallback(data: Map<String, Any?>, reason: String): Boolean {
        if (wasRecentlyActioned(callKey(data))) {
            Log.i(FALLBACK_TAG, "fallback bloqueado porque ação já foi enviada reason=$reason key=${callKey(data)}")
            return true
        }
        val serviceFallback = buildFallbackNotification(data, overlayAllowed = reason != "overlay_sem_permissao")
        startForeground(NOTIFICATION_ID, serviceFallback)
        val emitted = FoxGoCallFallbackNotifier.show(this, data, source = "overlay-service-$reason")
        Log.i(FALLBACK_TAG, "fallback heads-up resultado=$emitted motivo=$reason callId=${data["callId"]} orderId=${data["orderId"]}")
        return emitted
    }

    private fun dismissOverlay() {
        mainHandler.removeCallbacksAndMessages(null)
        overlayManager?.dismiss(notify = false)
        isShowing = false
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun dismissAllVisuals(reason: String) {
        Log.i(TAG, "limpando overlay/fallback reason=$reason activeKey=$activeCallKey")
        mainHandler.removeCallbacksAndMessages(null)
        overlayManager?.dismiss(notify = false)
        isShowing = false
        FoxGoCallFallbackNotifier.cancel(this, source = reason)
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(NOTIFICATION_ID)
        } catch (exception: Exception) {
            Log.e(TAG, "falha ao cancelar notificação de serviço reason=$reason", exception)
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun payloadFromIntent(intent: Intent?): Map<String, Any?> {
        if (intent == null) return emptyMap()
        val extras = intent.extras ?: return emptyMap()
        return extras.keySet().associateWith { key -> extras.get(key) }
    }

    private fun buildFallbackNotification(data: Map<String, Any?>, overlayAllowed: Boolean): Notification {
        ensureChannel()
        val orderId = first(data, "orderId", "order_id", "id")
        val callId = first(data, "callId", "call_id").ifBlank { orderId }
        val title = if (overlayAllowed) moduleTitle(data) else "Permita aparecer sobre outros apps"
        val earning = first(data, "earning", "driverEarningAmount", "driver_earning", "deliveryCharge")
        val distance = first(data, "distance", "totalDistanceKm", "total_distance")
        val payment = paymentLabel(first(data, "paymentMethod", "payment_method"))
        val text = if (overlayAllowed) compactText(orderId, earning, distance, payment) else "Toque para abrir o app e atender pela tela de solicitações"
        val openIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_OPEN_ORDER_REQUEST, true)
            putExtra(EXTRA_OVERLAY_ACTION, "onNewCallFallbackOpen")
            if (orderId.isNotEmpty()) putExtra(EXTRA_ORDER_ID, orderId)
            if (callId.isNotEmpty()) putExtra(EXTRA_CALL_ID, callId)
            data.forEach { (key, value) -> putExtraValue(key, value) }
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            3101,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
        val acceptIntent = actionIntent(ACTION_ACCEPT, "onNewCallAccept", data)
        val rejectIntent = actionIntent(ACTION_REJECT, "onNewCallReject", data)
        val acceptPendingIntent = PendingIntent.getService(
            this,
            3102,
            acceptIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
        val rejectPendingIntent = PendingIntent.getService(
            this,
            3103,
            rejectIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setPriority(Notification.PRIORITY_MAX)
                .setCategory(Notification.CATEGORY_CALL)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOnlyAlertOnce(false)
                .setFullScreenIntent(pendingIntent, true)
                .setSound(callSoundUri())
                .setVibrate(longArrayOf(0, 500, 250, 500))
                .addAction(R.drawable.notification_icon, "Aceitar", acceptPendingIntent)
                .addAction(R.drawable.notification_icon, "Recusar", rejectPendingIntent)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setPriority(Notification.PRIORITY_MAX)
                .setCategory(Notification.CATEGORY_CALL)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOnlyAlertOnce(false)
                .setFullScreenIntent(pendingIntent, true)
                .setSound(callSoundUri())
                .setVibrate(longArrayOf(0, 500, 250, 500))
                .addAction(R.drawable.notification_icon, "Aceitar", acceptPendingIntent)
                .addAction(R.drawable.notification_icon, "Recusar", rejectPendingIntent)
                .build()
        }
    }

    private fun buildServiceNotification(data: Map<String, Any?>): Notification {
        ensureServiceChannel()
        val orderId = first(data, "orderId", "order_id", "id")
        val text = if (orderId.isNotEmpty()) "Preparando chamada #$orderId" else "Preparando nova chamada"
        val openIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_OPEN_ORDER_REQUEST, true)
            if (orderId.isNotEmpty()) putExtra(EXTRA_ORDER_ID, orderId)
            data.forEach { (key, value) -> putExtraValue(key, value) }
        }
        val pendingIntent = PendingIntent.getActivity(this, 3111, openIntent, PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag())
        return Notification.Builder(this, SERVICE_CHANNEL_ID)
            .setSmallIcon(R.drawable.notification_icon)
            .setContentTitle("Fox GO chamada em andamento")
            .setContentText(text)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun actionIntent(serviceAction: String, overlayAction: String, data: Map<String, Any?>): Intent {
        Log.i(FALLBACK_TAG, "PendingIntent action=$serviceAction overlayAction=$overlayAction requestCode=${if (serviceAction == ACTION_ACCEPT) 3102 else 3103} orderId=${data["orderId"]} callId=${data["callId"]}")
        return Intent(this, NewCallOverlayService::class.java).apply {
            action = serviceAction
            putExtra(EXTRA_OPEN_ORDER_REQUEST, true)
            putExtra(EXTRA_OVERLAY_ACTION, overlayAction)
            data.forEach { (key, value) -> putExtraValue(key, value) }
        }
    }

    private fun dispatchCallAction(action: String, data: Map<String, Any?>, source: String) {
        val payload = lastPayload + data
        if (payload.isNotEmpty()) lastPayload = payload
        val orderId = detectOrderId(payload)
        val key = callKey(payload)
        val actionKey = "$action|$key"
        if (key.isNotBlank() && wasRecentlyActioned(key, action)) {
            Log.i(CALL_ACTION_TAG, "ação duplicada bloqueada action=$action source=$source key=$key")
            dismissAllVisuals("duplicated_action_$source")
            stopSelf()
            return
        }
        lastActionKey = actionKey
        lastActionAtMs = System.currentTimeMillis()

        Log.i(CALL_ACTION_TAG, "action=$action source=$source payload=$payload orderId=$orderId callId=${payload["callId"]} key=$key")
        if (orderId == null) {
            Log.w(CALL_ACTION_TAG, "action=$action sem orderId detectável; abrindo app sem crash source=$source payload=$payload")
        }
        dismissAllVisuals("action_$source")
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_OVERLAY_ACTION, action)
            putExtra(EXTRA_OPEN_ORDER_REQUEST, true)
            orderId?.let { putExtra(EXTRA_ORDER_ID, it) }
            payload["callId"]?.toString()?.let { putExtra(EXTRA_CALL_ID, it) }
            payload.forEach { (payloadKey, value) -> putExtraValue(payloadKey, value) }
        }
        try {
            Log.i(CALL_ACTION_TAG, "abrindo app para entregar ação ao Flutter callbackDisponivel=desconhecido source=$source orderId=$orderId")
            startActivity(intent)
            Log.i(CALL_ACTION_TAG, "ação pendente enviada para MainActivity source=$source orderId=$orderId")
            stopSelf()
        } catch (exception: Exception) {
            Log.e(CALL_ACTION_TAG, "erro ao abrir app/entregar ação; mantendo action no intent source=$source action=$action orderId=$orderId", exception)
        }
    }

    private fun detectOrderId(data: Map<String, Any?>): String? {
        return listOf("orderId", "order_id", "id", "callId", "call_id")
            .mapNotNull { key -> data[key]?.toString()?.takeIf { value -> value.isNotBlank() && value != "null" } }
            .firstOrNull()
    }

    private fun callKey(data: Map<String, Any?>): String {
        return detectOrderId(data).orEmpty()
    }

    private fun wasRecentlyActioned(key: String, action: String? = null): Boolean {
        if (key.isBlank()) return false
        val now = System.currentTimeMillis()
        val last = lastActionKey ?: return false
        val sameKey = last.endsWith("|$key")
        val sameAction = action == null || last.startsWith("$action|")
        return sameKey && sameAction && (now - lastActionAtMs) < ACTION_DEDUPE_TTL_MS
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

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Fox GO chamadas", NotificationManager.IMPORTANCE_MAX).apply {
                    description = "Fallback acionável para novas solicitações"
                    setSound(callSoundUri(), AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 250, 500)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
            )
        }
    }

    private fun ensureServiceChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(SERVICE_CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(SERVICE_CHANNEL_ID, "Fox GO overlay service", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Notificação técnica do serviço de overlay"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                }
            )
        }
    }

    private fun callSoundUri(): Uri = Uri.parse("android.resource://$packageName/${R.raw.notification}")

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

    private fun immutableFlag(): Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

    companion object {
        private const val TAG = "FoxGoOverlayService"
        private const val FALLBACK_TAG = "FoxGoCallFallback"
        private const val CALL_ACTION_TAG = "FoxGoCallAction"
        private const val CHANNEL_ID = "foxgo_order_overlay_v2"
        private const val SERVICE_CHANNEL_ID = "foxgo_overlay_service_v1"
        private const val NOTIFICATION_ID = 3100
        private const val OVERLAY_CONFIRMATION_DELAY_MS = 700L
        private const val ACTION_DEDUPE_TTL_MS = 10_000L
        const val ACTION_SHOW = "com.foxgo.entregador.overlay.SHOW"
        const val ACTION_UPDATE = "com.foxgo.entregador.overlay.UPDATE"
        const val ACTION_DISMISS = "com.foxgo.entregador.overlay.DISMISS"
        const val ACTION_ACCEPT = "com.foxgo.entregador.overlay.ACCEPT"
        const val ACTION_REJECT = "com.foxgo.entregador.overlay.REJECT"
        const val EXTRA_OPEN_ORDER_REQUEST = "open_order_request"
        const val EXTRA_OVERLAY_ACTION = "overlay_action"
        const val EXTRA_ORDER_ID = "orderId"
        const val EXTRA_CALL_ID = "callId"
        var isShowing: Boolean = false
            private set
    }
}
