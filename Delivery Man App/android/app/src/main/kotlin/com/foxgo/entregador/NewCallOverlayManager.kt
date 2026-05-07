package com.foxgo.entregador

import android.content.Context
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
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

    fun isShowing(): Boolean = overlayView != null

    fun show(data: Map<String, Any?>): Boolean {
        if (!canDrawOverlays()) return false
        val newCallId = (data["callId"] ?: data["orderId"] ?: data["rideId"])?.toString() ?: "unknown"
        if (isShowing() && currentCallId == newCallId) {
            update(data)
            return true
        }
        dismiss(notify = false)
        currentData = data
        currentCallId = newCallId

        val view = LayoutInflater.from(context).inflate(R.layout.view_new_call_overlay, null)
        bindData(view, data)

        view.findViewById<Button>(R.id.btnAccept).setOnClickListener {
            onAction("onNewCallAccept", currentData + mapOf("callId" to currentCallId))
            dismiss(notify = false)
        }
        view.findViewById<Button>(R.id.btnReject).setOnClickListener {
            onAction("onNewCallReject", currentData + mapOf("callId" to currentCallId))
            dismiss(notify = false)
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM
            y = 24
        }

        windowManager.addView(view, params)
        overlayView = view
        startAlarm()
        return true
    }

    fun update(data: Map<String, Any?>): Boolean {
        if (overlayView == null) return show(data)
        currentData = currentData + data
        bindData(overlayView!!, currentData)
        return true
    }

    fun dismiss(notify: Boolean = true) {
        stopAlarm()
        overlayView?.let {
            windowManager.removeView(it)
            overlayView = null
            if (notify) onAction("onNewCallDismissed", currentData + mapOf("callId" to currentCallId))
            currentCallId = null
        }
    }

    private fun startAlarm() {
        try {
            stopAlarm()
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

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
        } catch (_: Exception) {
            stopAlarm()
        }
    }

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

        val origin = data["originName"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando detalhes"
        val pickup = data["pickupAddress"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando endereço de retirada"
        val destination = data["destinationAddress"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando destino"
        val earning = data["earning"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val distance = data["distance"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val payment = data["paymentMethod"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"

        view.findViewById<TextView>(R.id.tvTitle).text = data["title"]?.toString().takeUnless { it.isNullOrBlank() } ?: title
        view.findViewById<TextView>(R.id.tvType).text = "Tipo: $tipo"
        view.findViewById<TextView>(R.id.tvOrigin).text = "Origem: $origin"
        view.findViewById<TextView>(R.id.tvPickup).text = "Retirada: $pickup"
        view.findViewById<TextView>(R.id.tvDestination).text = "Destino: $destination"
        view.findViewById<TextView>(R.id.tvEarning).text = "Você recebe: $earning"
        view.findViewById<TextView>(R.id.tvDistance).text = "Distância: $distance"
        view.findViewById<TextView>(R.id.tvPayment).text = "Pagamento: $payment"
    }
}
