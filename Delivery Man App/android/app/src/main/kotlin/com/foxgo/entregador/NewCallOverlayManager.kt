package com.foxgo.entregador

import android.content.Context
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class NewCallOverlayManager(
    private val context: Context,
    private val onAction: (String, Map<String, Any?>) -> Unit,
) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentCallId: String? = null
    private var currentData: Map<String, Any?> = emptyMap()

    fun canDrawOverlays(): Boolean = Settings.canDrawOverlays(context)

    fun isShowing(): Boolean {
        val view = overlayView ?: return false
        val attached = Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT || view.isAttachedToWindow
        if (!attached) {
            Log.w(TAG, "overlayView sem anexação detectada; limpando estado preso callId=$currentCallId")
            clearOverlayState()
            return false
        }
        return true
    }

    fun show(data: Map<String, Any?>): Boolean {
        val overlayAllowed = canDrawOverlays()
        Log.i(TAG, "Settings.canDrawOverlays=$overlayAllowed no momento da chamada")
        if (!overlayAllowed) return false
        val newCallId = (data["callId"] ?: data["orderId"] ?: data["rideId"])?.toString() ?: "unknown"
        if (isShowing() && currentCallId == newCallId) {
            return update(data)
        }
        dismiss(notify = false)
        currentData = data
        currentCallId = newCallId

        val view = LayoutInflater.from(context).inflate(R.layout.view_new_call_overlay, null)
        bindData(view, data)

        view.findViewById<Button>(R.id.btnAccept).setOnClickListener {
            val actionData = actionPayload()
            Log.i(CALL_ACTION_TAG, "clique Aceitar no overlay payload=$actionData orderId=${actionData["orderId"]} callId=${actionData["callId"]}")
            try {
                onAction("onNewCallAccept", actionData)
            } catch (exception: Exception) {
                Log.e(CALL_ACTION_TAG, "erro ao entregar Aceitar do overlay orderId=${actionData["orderId"]} callId=${actionData["callId"]}", exception)
            }
            dismiss(notify = false)
        }
        view.findViewById<Button>(R.id.btnReject).setOnClickListener {
            val actionData = actionPayload()
            Log.i(CALL_ACTION_TAG, "clique Recusar no overlay payload=$actionData orderId=${actionData["orderId"]} callId=${actionData["callId"]}")
            try {
                onAction("onNewCallReject", actionData)
            } catch (exception: Exception) {
                Log.e(CALL_ACTION_TAG, "erro ao entregar Recusar do overlay orderId=${actionData["orderId"]} callId=${actionData["callId"]}", exception)
            }
            dismiss(notify = false)
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_DIM_BEHIND,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            dimAmount = 0.8f
        }

        Log.i(TAG, "tentativa de WindowManager.addView callId=$newCallId")
        return try {
            windowManager.addView(view, params)
            overlayView = view
            startAlarm()
            Log.i(TAG, "sucesso do addView callId=$newCallId")
            true
        } catch (securityException: SecurityException) {
            Log.e(TAG, "erro do addView: SecurityException callId=$newCallId", securityException)
            clearOverlayState()
            false
        } catch (badTokenException: WindowManager.BadTokenException) {
            Log.e(TAG, "erro do addView: BadTokenException callId=$newCallId", badTokenException)
            clearOverlayState()
            false
        } catch (illegalStateException: IllegalStateException) {
            Log.e(TAG, "erro do addView: IllegalStateException callId=$newCallId", illegalStateException)
            clearOverlayState()
            false
        } catch (exception: Exception) {
            Log.e(TAG, "erro do addView: Exception callId=$newCallId", exception)
            clearOverlayState()
            false
        }
    }

    fun update(data: Map<String, Any?>): Boolean {
        if (!isShowing()) return show(data)
        currentData = currentData + data
        val view = overlayView ?: return show(currentData)
        Log.i(TAG, "tentativa de updateView callId=$currentCallId")
        return try {
            bindData(view, currentData)
            windowManager.updateViewLayout(view, view.layoutParams)
            Log.i(TAG, "sucesso do updateView callId=$currentCallId")
            true
        } catch (securityException: SecurityException) {
            Log.e(TAG, "erro do updateView: SecurityException callId=$currentCallId", securityException)
            clearOverlayState()
            false
        } catch (badTokenException: WindowManager.BadTokenException) {
            Log.e(TAG, "erro do updateView: BadTokenException callId=$currentCallId", badTokenException)
            clearOverlayState()
            false
        } catch (illegalStateException: IllegalStateException) {
            Log.e(TAG, "erro do updateView: IllegalStateException callId=$currentCallId", illegalStateException)
            clearOverlayState()
            false
        } catch (exception: Exception) {
            Log.e(TAG, "erro do updateView: Exception callId=$currentCallId", exception)
            clearOverlayState()
            false
        }
    }

    fun dismiss(notify: Boolean = true) {
        stopAlarm()
        overlayView?.let {
            Log.i(TAG, "tentativa de removeView callId=$currentCallId")
            try {
                windowManager.removeView(it)
                Log.i(TAG, "sucesso do removeView callId=$currentCallId")
            } catch (securityException: SecurityException) {
                Log.e(TAG, "erro do removeView: SecurityException callId=$currentCallId", securityException)
            } catch (badTokenException: WindowManager.BadTokenException) {
                Log.e(TAG, "erro do removeView: BadTokenException callId=$currentCallId", badTokenException)
            } catch (illegalStateException: IllegalStateException) {
                Log.e(TAG, "erro do removeView: IllegalStateException callId=$currentCallId", illegalStateException)
            } catch (exception: Exception) {
                Log.e(TAG, "erro do removeView: Exception callId=$currentCallId", exception)
            } finally {
                if (notify) onAction("onNewCallDismissed", currentData + mapOf("callId" to currentCallId))
                clearOverlayState()
            }
        }
    }

    private fun clearOverlayState() {
        stopAlarm()
        overlayView = null
        currentCallId = null
    }

    private fun startAlarm() {
        try {
            stopAlarm()
            val uri = callSoundUri()
            Log.i(TAG, "iniciando som próprio da chamada uri=$uri")

            mediaPlayer = MediaPlayer().apply {
                setDataSource(context, uri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
        } catch (exception: Exception) {
            Log.e(TAG, "erro ao iniciar som próprio da chamada", exception)
            stopAlarm()
        }
    }

    private fun actionPayload(): Map<String, Any?> {
        val callId = currentCallId ?: currentData["callId"]?.toString() ?: currentData["orderId"]?.toString()
        return currentData + mapOf("callId" to callId)
    }

    private fun callSoundUri(): Uri = Uri.parse("android.resource://${context.packageName}/${R.raw.notification}")

    private fun stopAlarm() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null
    }

    private fun bindData(view: View, data: Map<String, Any?>) {
        val rawType = ((data["rawType"] ?: data["type"] ?: data["moduleType"])?.toString() ?: "").lowercase()
        val ride = (data["isRide"] as? Boolean) == true || rawType.contains("ride") || rawType.contains("taxi") || rawType.contains("corrida")
        val title = when {
            ride -> "Nova corrida disponível"
            rawType.contains("food") -> "Nova entrega de comida disponível"
            rawType.contains("pharmacy") || rawType.contains("farm") -> "Nova entrega de farmácia disponível"
            rawType.contains("grocery") || rawType.contains("market") || rawType.contains("mercado") -> "Nova entrega de mercado disponível"
            rawType.contains("parcel") || rawType.contains("encomenda") -> "Nova entrega disponível"
            else -> "Nova chamada disponível"
        }

        val tipo = when {
            ride -> "Corrida"
            rawType.contains("food") -> "Food"
            rawType.contains("pharmacy") || rawType.contains("farm") -> "Farmácia"
            rawType.contains("grocery") || rawType.contains("market") || rawType.contains("mercado") -> "Mercado"
            rawType.contains("parcel") || rawType.contains("encomenda") -> "Entrega"
            else -> "Entrega"
        }

        val items = data["itemsSummary"]?.toString().takeUnless { it.isNullOrBlank() }
        val origin = data["originName"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando detalhes"
        val pickup = data["pickupAddress"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando endereço de retirada"
        val destination = data["destinationAddress"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando destino"
        val earning = data["earning"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val distance = data["distance"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val payment = data["paymentMethod"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"

        val displayTitle = data["title"]?.toString().takeUnless { it.isNullOrBlank() } ?: title
        view.findViewById<TextView>(R.id.tvTitle).text = "FOX GO • $displayTitle"
        view.findViewById<TextView>(R.id.tvType).text = "Tipo: $tipo"
        view.findViewById<TextView>(R.id.tvItems).apply {
            visibility = if (items == null) View.GONE else View.VISIBLE
            text = items?.let { "Itens comprados:\n$it" } ?: ""
        }
        view.findViewById<TextView>(R.id.tvOrigin).text = "Origem: $origin"
        view.findViewById<TextView>(R.id.tvPickup).text = "Retirada: $pickup"
        view.findViewById<TextView>(R.id.tvDestination).text = "Destino: $destination"
        view.findViewById<TextView>(R.id.tvEarning).text = "Você recebe: $earning"
        view.findViewById<TextView>(R.id.tvDistance).text = "Distância: $distance"
        view.findViewById<TextView>(R.id.tvPayment).text = "Pagamento: $payment"
    }

    companion object {
        private const val TAG = "FoxGoOverlayWindow"
        private const val CALL_ACTION_TAG = "FoxGoCallAction"
    }
}
