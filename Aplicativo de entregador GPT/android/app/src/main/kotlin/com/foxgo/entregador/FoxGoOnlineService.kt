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
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.net.HttpURLConnection
import java.net.URL

class FoxGoOnlineService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    @Volatile
    private var isPolling = false
    private var lastRoutedOrderId: String? = null
    private var lastRoutedAtMs: Long = 0L
    private val republishRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                republishOnlineNotification("watchdog")
                handler.postDelayed(this, REPUBLISH_INTERVAL_MS)
            }
        }
    }
    private val latestOrdersRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            if (isPolling) {
                scheduleLatestOrdersPolling()
                return
            }
            isPolling = true
            Thread {
                try {
                    refreshLatestOrdersWatchdog()
                } finally {
                    isPolling = false
                    if (isRunning) {
                        handler.post { scheduleLatestOrdersPolling() }
                    }
                }
            }.start()
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
                handler.removeCallbacks(latestOrdersRunnable)
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
                    handler.removeCallbacks(latestOrdersRunnable)
                    handler.postDelayed(republishRunnable, REPUBLISH_INTERVAL_MS)
                    scheduleLatestOrdersPolling(initial = true)
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
        handler.removeCallbacks(latestOrdersRunnable)
        isRunning = false
        super.onDestroy()
    }

    private fun scheduleLatestOrdersPolling(initial: Boolean = false) {
        val delay = if (initial) POLL_INITIAL_DELAY_MS else POLL_INTERVAL_MS
        handler.postDelayed(latestOrdersRunnable, delay)
    }

    private fun refreshLatestOrdersWatchdog() {
        Log.i(REFRESH_TAG, "source=online-service-watchdog inicio")
        val prefs = getSharedPreferences(FLUTTER_SHARED_PREFS, Context.MODE_PRIVATE)
        val token = prefs.getString("flutter.$TOKEN_KEY", null).orEmpty().trim()
        Log.i(REFRESH_TAG, "tokenPresente=${token.isNotEmpty()}")
        if (token.isEmpty()) return

        val baseUrl = BASE_URL
        if (baseUrl.isBlank()) return
        if (NewCallOverlayService.isShowing) return

        val endpoint = "$baseUrl$LATEST_ORDERS_PATH$token"
        val connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = REQUEST_TIMEOUT_MS
            readTimeout = REQUEST_TIMEOUT_MS
            setRequestProperty("Accept", "application/json")
            val language = prefs.getString("flutter.$LANGUAGE_KEY", DEFAULT_LANGUAGE).orEmpty().ifBlank { DEFAULT_LANGUAGE }
            val zoneId = prefs.getString("flutter.$ZONE_ID_KEY", "null").orEmpty().ifBlank { "null" }
            setRequestProperty("X-localization", language)
            setRequestProperty("zoneId", zoneId)
            setRequestProperty("Authorization", "Bearer $token")
        }

        try {
            val statusCode = connection.responseCode
            Log.i(REFRESH_TAG, "statusCode=$statusCode")
            if (statusCode !in 200..299) return

            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val dataArray = extractOrders(body)
            Log.i(REFRESH_TAG, "pedidosEncontrados=${dataArray.length()}")
            if (dataArray.length() == 0) return
            val order = dataArray.optJSONObject(0) ?: return
            val orderId = detectOrderId(order)
            if (orderId.isEmpty()) return
            Log.i(REFRESH_TAG, "orderId=$orderId")
            if (shouldSkipByDedupe(orderId)) return

            val payload = buildOverlayPayloadFromOrder(order, orderId)
            val action = if (NewCallOverlayService.isShowing) NewCallOverlayService.ACTION_UPDATE else NewCallOverlayService.ACTION_SHOW
            val intent = Intent(this, NewCallOverlayService::class.java).apply {
                this.action = action
                payload.forEach { (key, value) -> putExtra(key, value) }
            }
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            lastRoutedOrderId = orderId
            lastRoutedAtMs = System.currentTimeMillis()
            Log.i(REFRESH_TAG, "overlay acionado")
        } catch (exception: Exception) {
            Log.e(REFRESH_TAG, "erro=${exception.message}", exception)
        } finally {
            connection.disconnect()
        }
    }

    private fun shouldSkipByDedupe(orderId: String): Boolean {
        val lastId = lastRoutedOrderId
        val now = System.currentTimeMillis()
        if (lastId == orderId && (now - lastRoutedAtMs) < DEDUPE_TTL_MS) {
            Log.i(REFRESH_TAG, "dedupeBloqueado orderId=$orderId")
            return true
        }
        return false
    }

    private fun detectOrderId(order: JSONObject): String {
        return order.optString("id").ifEmpty { order.optString("order_id") }.ifEmpty { order.optString("orderId") }
    }

    private fun extractOrders(body: String): JSONArray {
        val normalizedBody = body.trim()
        if (normalizedBody.isEmpty()) return JSONArray()

        return when (val root = JSONTokener(normalizedBody).nextValue()) {
            is JSONArray -> root
            is JSONObject -> when (val data = root.opt("data")) {
                is JSONArray -> data
                is JSONObject -> data.optJSONArray("orders") ?: JSONArray()
                else -> JSONArray()
            }
            else -> JSONArray()
        }
    }

    private fun buildOverlayPayloadFromOrder(order: JSONObject, orderId: String): Map<String, String> {
        val moduleType = order.optString("module_type").ifBlank { order.optString("moduleType") }.ifBlank { "latest_orders" }
        return mapOf(
            "callId" to orderId,
            "orderId" to orderId,
            "type" to "latest_orders",
            "rawType" to moduleType,
            "moduleType" to moduleType,
            "originName" to order.optString("store_name").ifBlank { order.optString("store") },
            "pickupAddress" to order.optString("pickup_address"),
            "destinationAddress" to order.optString("destination_address"),
            "earning" to order.optString("delivery_charge").ifBlank { order.optString("earning") },
            "distance" to order.optString("distance"),
            "paymentMethod" to order.optString("payment_method"),
        )
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
        private const val POLL_INITIAL_DELAY_MS = 5_000L
        private const val POLL_INTERVAL_MS = 15_000L
        private const val DEDUPE_TTL_MS = 30_000L
        private const val REQUEST_TIMEOUT_MS = 8_000
        private const val REFRESH_TAG = "FoxGoOrderRefresh"
        private const val BASE_URL = "https://admin.foxgodelivery.com.br"
        private const val LATEST_ORDERS_PATH = "/api/v1/delivery-man/latest-orders?token="
        private const val FLUTTER_SHARED_PREFS = "FlutterSharedPreferences"
        private const val TOKEN_KEY = "sixam_mart_delivery_token"
        private const val LANGUAGE_KEY = "foxgo_delivery_language_code"
        private const val ZONE_ID_KEY = "cache_zone_id"
        private const val DEFAULT_LANGUAGE = "pt"

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
