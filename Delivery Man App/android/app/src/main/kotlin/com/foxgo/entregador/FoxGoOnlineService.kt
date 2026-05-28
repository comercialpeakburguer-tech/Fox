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
            Log.i(
                REFRESH_TAG,
                "payloadNativo orderId=$orderId module=${payload["moduleType"]} earning=${payload["earning"]} distance=${payload["distance"]} expiresAt=${payload["expiresAt"]} ttl=${payload["ttlSeconds"]}"
            )
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
        return firstString(order, "id", "order_id", "orderId", "call_id", "callId")
    }

    private fun extractOrders(body: String): JSONArray {
        val normalizedBody = body.trim()
        if (normalizedBody.isEmpty()) return JSONArray()

        return when (val root = JSONTokener(normalizedBody).nextValue()) {
            is JSONArray -> root
            is JSONObject -> when (val data = root.opt("data")) {
                is JSONArray -> data
                is JSONObject -> data.optJSONArray("orders")
                    ?: data.optJSONArray("latest_orders")
                    ?: data.optJSONArray("latestOrders")
                    ?: data.optJSONArray("requests")
                    ?: JSONArray()
                else -> root.optJSONArray("orders")
                    ?: root.optJSONArray("latest_orders")
                    ?: root.optJSONArray("latestOrders")
                    ?: JSONArray()
            }
            else -> JSONArray()
        }
    }

    private fun buildOverlayPayloadFromOrder(order: JSONObject, orderId: String): Map<String, String> {
        val moduleType = firstString(order, "module_type", "moduleType", "module", "order_type", "orderType").ifBlank { "latest_orders" }
        val orderType = firstString(order, "order_type", "orderType").ifBlank { moduleType }
        val paymentMethod = firstString(order, "payment_method", "paymentMethod")
        val originName = firstString(order, "store_name", "storeName", "store", "restaurant_name", "shop_name", "pickup_name", "sender_name")
        val pickupAddress = firstString(order, "pickup_address", "pickupAddress", "store_address", "storeAddress", "sender_address")
            .ifBlank { firstStringObject(order, "store", "address") }
            .ifBlank { firstStringObject(order, "pickup", "address") }
        val destinationAddress = firstString(order, "destination_address", "destinationAddress", "delivery_address", "deliveryAddress", "receiver_address")
            .ifBlank { firstStringObject(order, "delivery_address", "address") }
            .ifBlank { firstStringObject(order, "deliveryAddress", "address") }
            .ifBlank { firstStringObject(order, "receiver_details", "address") }
            .ifBlank { firstStringObject(order, "receiverDetails", "address") }
        val receiverName = firstString(order, "receiver_name", "receiverName", "customer_name", "customerName")
            .ifBlank { firstStringObject(order, "receiver_details", "contact_person_name") }
            .ifBlank { firstStringObject(order, "delivery_address", "contact_person_name") }
            .ifBlank { firstStringObject(order, "deliveryAddress", "contactPersonName") }
        val earning = firstString(
            order,
            "driver_earning",
            "driverEarning",
            "driver_earning_amount",
            "driverEarningAmount",
            "dm_earning",
            "dmEarning",
            "original_delivery_charge",
            "originalDeliveryCharge",
            "delivery_charge",
            "deliveryCharge",
            "earning",
            "amount"
        )
        val tips = firstString(order, "dm_tips", "dmTips", "tips", "tip")
        val distance = firstString(order, "distance", "distance_km", "distanceKm", "total_distance", "totalDistance", "totalDistanceKm")
        val expiresAt = firstString(order, "expires_at", "expiresAt", "offer_expires_at", "offerExpiresAt", "timeout_at", "timeoutAt")
        val ttlSeconds = firstString(order, "ttl_seconds", "ttlSeconds", "timeout", "offer_timeout", "offerTimeout")
        val itemCount = firstString(order, "details_count", "detailsCount", "item_count", "itemCount", "items_count", "itemsCount")
        val title = when {
            isRideRaw(moduleType, orderType) -> "Nova corrida"
            isParcelRaw(moduleType, orderType) -> "Nova encomenda"
            isPharmacyRaw(moduleType) -> "Nova entrega de farmácia"
            isMarketRaw(moduleType) -> "Nova entrega de mercado"
            else -> "Nova chamada"
        }

        return mapOf(
            "callId" to orderId,
            "orderId" to orderId,
            "order_id" to orderId,
            "type" to "latest_orders",
            "rawType" to moduleType,
            "moduleType" to moduleType,
            "orderType" to orderType,
            "title" to title,
            "originName" to originName,
            "pickupAddress" to pickupAddress,
            "destinationAddress" to destinationAddress,
            "receiverName" to receiverName,
            "earning" to earning,
            "driverEarningAmount" to earning,
            "dmTips" to tips,
            "distance" to distance,
            "totalDistanceKm" to distance,
            "paymentMethod" to paymentMethod,
            "expiresAt" to expiresAt,
            "ttlSeconds" to ttlSeconds,
            "itemsCount" to itemCount,
            "isRide" to isRideRaw(moduleType, orderType).toString(),
            "isFood" to isFoodRaw(moduleType, orderType).toString(),
            "isParcel" to isParcelRaw(moduleType, orderType).toString(),
            "isMarket" to isMarketRaw(moduleType).toString(),
            "isPharmacy" to isPharmacyRaw(moduleType).toString(),
        )
    }

    private fun firstString(json: JSONObject, vararg keys: String): String {
        for (key in keys) {
            if (!json.has(key) || json.isNull(key)) continue
            val raw = json.opt(key)
            val value = when (raw) {
                is JSONObject, is JSONArray -> ""
                else -> raw?.toString().orEmpty()
            }.trim()
            if (value.isNotBlank() && value != "null") return value
        }
        return ""
    }

    private fun firstStringObject(json: JSONObject, objectKey: String, valueKey: String): String {
        val child = json.optJSONObject(objectKey) ?: return ""
        return firstString(child, valueKey, snakeToCamel(valueKey), camelToSnake(valueKey))
    }

    private fun snakeToCamel(value: String): String {
        return value.split("_").filter { it.isNotBlank() }.mapIndexed { index, part ->
            if (index == 0) part else part.replaceFirstChar { char -> char.uppercase() }
        }.joinToString("")
    }

    private fun camelToSnake(value: String): String {
        return value.replace(Regex("([a-z])([A-Z])"), "$1_$2").lowercase()
    }

    private fun isRideRaw(moduleType: String, orderType: String): Boolean {
        val raw = "$moduleType|$orderType".lowercase()
        return raw.contains("ride") || raw.contains("taxi") || raw.contains("corrida")
    }

    private fun isParcelRaw(moduleType: String, orderType: String): Boolean {
        val raw = "$moduleType|$orderType".lowercase()
        return raw.contains("parcel") || raw.contains("encomenda")
    }

    private fun isMarketRaw(moduleType: String): Boolean {
        val raw = moduleType.lowercase()
        return raw.contains("grocery") || raw.contains("market") || raw.contains("mercado")
    }

    private fun isPharmacyRaw(moduleType: String): Boolean {
        val raw = moduleType.lowercase()
        return raw.contains("pharmacy") || raw.contains("farm")
    }

    private fun isFoodRaw(moduleType: String, orderType: String): Boolean {
        val raw = "$moduleType|$orderType".lowercase()
        if (isParcelRaw(moduleType, orderType) || isRideRaw(moduleType, orderType) || isMarketRaw(moduleType) || isPharmacyRaw(moduleType)) return false
        return raw.isBlank() || raw.contains("food") || raw.contains("restaurant") || raw.contains("comida") || raw.contains("latest_orders")
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
