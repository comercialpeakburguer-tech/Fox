package com.foxgo.entregador

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

object FoxGoCallRouter {
    private const val TAG = "FoxGoCallRoute"

    fun isCallPayload(data: Map<String, String>): Boolean {
        val type = payloadType(data).lowercase()
        val action = data["action"].orEmpty().lowercase()
        val titleBody = listOfNotNull(data["title"], data["body"]).joinToString(" ").lowercase()
        return type == "new_order"
            || type == "order_request"
            || type == "assign"
            || type == "latest_orders"
            || action == "driver_new_ride_request"
            || action.contains("new_order")
            || action.contains("order_request")
            || (payloadOrderId(data).isNotEmpty() && (titleBody.contains("nova ordem") || titleBody.contains("novo pedido") || titleBody.contains("new order") || titleBody.contains("order request")))
    }

    fun route(context: Context, data: Map<String, String>, source: String): Boolean {
        Log.i(TAG, "entrada source=$source keys=${data.keys} type=${payloadType(data)} action=${data["action"]} orderId=${payloadOrderId(data)}")
        if (!isCallPayload(data)) {
            Log.i(TAG, "payload ignorado source=$source keys=${data.keys} type=${payloadType(data)} action=${data["action"]}")
            return false
        }

        val payload = buildOverlayPayload(data)
        val callId = payload["callId"]?.toString().orEmpty()
        val orderId = payload["orderId"]?.toString().orEmpty()
        Log.i(TAG, "detectou new_order/order_request source=$source type=${payloadType(data)} action=${data["action"]} callId=$callId orderId=$orderId")
        if (callId.isEmpty()) {
            Log.w(TAG, "payload sem callId; emitindo fallback source=$source data=$data")
            return FoxGoCallFallbackNotifier.show(context, payload, source = "$source-sem-callId")
        }

        val action = if (NewCallOverlayService.isShowing) NewCallOverlayService.ACTION_UPDATE else NewCallOverlayService.ACTION_SHOW
        val canDraw = Settings.canDrawOverlays(context)
        Log.i("FoxGoOverlayService", "tentou start NewCallOverlayService action=$action canDraw=$canDraw source=$source callId=$callId")
        if (!canDraw) {
            return FoxGoCallFallbackNotifier.show(context, payload, source = "$source-overlay-sem-permissao")
        }

        return try {
            val intent = Intent(context, NewCallOverlayService::class.java).apply {
                this.action = action
                payload.forEach { (key, value) -> putExtraValue(key, value) }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.i("FoxGoOverlayService", "start service sucesso source=$source callId=$callId")
            true
        } catch (securityException: SecurityException) {
            Log.e("FoxGoOverlayService", "start service falha SecurityException source=$source callId=$callId", securityException)
            FoxGoCallFallbackNotifier.show(context, payload, source = "$source-security-exception")
        } catch (exception: Exception) {
            Log.e("FoxGoOverlayService", "start service falha source=$source callId=$callId", exception)
            FoxGoCallFallbackNotifier.show(context, payload, source = "$source-start-exception")
        }
    }

    private fun buildOverlayPayload(data: Map<String, String>): Map<String, Any?> {
        val orderId = payloadOrderId(data).ifEmpty { null }
        val rideId = data["ride_request_id"] ?: data["rideRequestId"] ?: data["trip_id"]
        val rawType = data["module_type"] ?: data["moduleType"] ?: payloadType(data)
        return mapOf(
            "callId" to (orderId ?: rideId ?: System.currentTimeMillis().toString()),
            "orderId" to orderId,
            "rideId" to rideId,
            "rawType" to rawType,
            "type" to payloadType(data),
            "moduleType" to (data["module_type"] ?: data["moduleType"]),
            "title" to data["title"],
            "originName" to (data["store_name"] ?: data["storeName"] ?: ""),
            "pickupAddress" to (data["pickup_address"] ?: data["store_address"] ?: ""),
            "destinationAddress" to (data["destination_address"] ?: data["delivery_address"] ?: ""),
            "earning" to (data["earning"] ?: data["order_amount"] ?: ""),
            "distance" to data["distance"].orEmpty(),
            "paymentMethod" to data["payment_method"].orEmpty(),
            "isRide" to (data["is_ride"] == "1" || rawType.contains("ride", ignoreCase = true)),
            "isFood" to isFoodPayload(data),
            "itemsSummary" to (data["items"] ?: data["order_items"] ?: data["order_details"]),
        )
    }

    private fun payloadType(data: Map<String, String>): String {
        return data["type"] ?: data["message_type"] ?: data["notification_type"] ?: data["body_loc_key"] ?: ""
    }

    private fun payloadOrderId(data: Map<String, String>): String {
        return data["order_id"] ?: data["orderId"] ?: data["title_loc_key"] ?: data["id"] ?: ""
    }

    private fun isFoodPayload(data: Map<String, String>): Boolean {
        val raw = listOfNotNull(
            data["module_type"],
            data["moduleType"],
            data["order_type"],
            data["orderType"],
            data["business_model"],
        ).joinToString("|").lowercase()
        if (raw.contains("parcel") || raw.contains("pharmacy") || raw.contains("grocery") || raw.contains("market") || raw.contains("ride") || raw.contains("taxi")) {
            return false
        }
        return raw.isEmpty() || raw.contains("food") || raw.contains("restaurant") || raw.contains("comida")
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
}
