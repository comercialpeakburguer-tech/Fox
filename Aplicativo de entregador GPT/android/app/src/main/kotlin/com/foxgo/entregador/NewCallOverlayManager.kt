package com.foxgo.entregador

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Color
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.CountDownTimer
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

class NewCallOverlayManager(
    private val context: Context,
    private val onAction: (String, Map<String, Any?>) -> Unit,
) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private var mediaPlayer: MediaPlayer? = null
    private var countdownTimer: CountDownTimer? = null
    private var currentCallId: String? = null
    private var currentData: Map<String, Any?> = emptyMap()
    private var actionLocked: Boolean = false
    private var rejectConfirmPending: Boolean = false
    private var acceptConfirmPending: Boolean = false

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
        actionLocked = false
        rejectConfirmPending = false
        acceptConfirmPending = false

        val view = LayoutInflater.from(context).inflate(R.layout.view_new_call_overlay, null)
        bindData(view, data)

        view.findViewById<Button>(R.id.btnAccept).setOnClickListener {
            if (actionLocked) return@setOnClickListener

            if (isCurrentCallExpired()) {
                expireCurrentCall()
                return@setOnClickListener
            }

            if (rejectConfirmPending) {
                rejectConfirmPending = false
                bindData(view, currentData)
                return@setOnClickListener
            }

            if (!acceptConfirmPending) {
                acceptConfirmPending = true
                bindData(view, currentData)
                return@setOnClickListener
            }

            actionLocked = true
            onAction("onNewCallAccept", currentData + mapOf("callId" to currentCallId, "confirmed" to true))
            dismiss(notify = false)
        }
        view.findViewById<Button>(R.id.btnReject).setOnClickListener {
            if (actionLocked) return@setOnClickListener

            if (isCurrentCallExpired()) {
                expireCurrentCall()
                return@setOnClickListener
            }

            if (acceptConfirmPending) {
                acceptConfirmPending = false
                bindData(view, currentData)
                return@setOnClickListener
            }

            if (!rejectConfirmPending) {
                rejectConfirmPending = true
                bindData(view, currentData)
                return@setOnClickListener
            }

            actionLocked = true
            onAction("onNewCallReject", currentData + mapOf("callId" to currentCallId, "confirmed" to true))
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
        startCountdown(currentData)
        return true
    }

    fun update(data: Map<String, Any?>): Boolean {
        if (overlayView == null) return show(data)
        currentData = currentData + data
        bindData(overlayView!!, currentData)
        startCountdown(currentData)
        return true
    }

    fun dismiss(notify: Boolean = true) {
        stopAlarm()
        stopCountdown()
        overlayView?.let {
            windowManager.removeView(it)
            overlayView = null
            if (notify) onAction("onNewCallDismissed", currentData + mapOf("callId" to currentCallId))
            currentCallId = null
            actionLocked = false
            rejectConfirmPending = false
            acceptConfirmPending = false
        }
    }



    private fun isCurrentCallExpired(): Boolean {
        val remainingSeconds = readRemainingSeconds(currentData)
        return remainingSeconds != null && remainingSeconds <= 0L
    }

    private fun startCountdown(data: Map<String, Any?>) {
        stopCountdown()

        val view = overlayView ?: return
        val remainingSeconds = readRemainingSeconds(data)

        if (remainingSeconds == null) {
            view.findViewById<TextView>(R.id.tvCountdown).text = "Tempo: aguardando"
            return
        }

        if (remainingSeconds <= 0L) {
            view.findViewById<TextView>(R.id.tvCountdown).text = "Chamada expirada"
            expireCurrentCall()
            return
        }

        updateCountdownText(view, remainingSeconds)

        countdownTimer = object : CountDownTimer(remainingSeconds * 1000L, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsLeft = ((millisUntilFinished + 999L) / 1000L).coerceAtLeast(0L)
                overlayView?.let { updateCountdownText(it, secondsLeft) }
            }

            override fun onFinish() {
                overlayView?.let { updateCountdownText(it, 0L) }
                expireCurrentCall()
            }
        }.start()
    }

    private fun stopCountdown() {
        try {
            countdownTimer?.cancel()
        } catch (_: Exception) {
        }
        countdownTimer = null
    }

    private fun updateCountdownText(view: View, secondsLeft: Long) {
        val text = if (secondsLeft <= 0L) {
            "Chamada expirada"
        } else {
            "Tempo restante: ${formatSeconds(secondsLeft)}"
        }
        view.findViewById<TextView>(R.id.tvCountdown).text = text
    }

    private fun formatSeconds(seconds: Long): String {
        val safeSeconds = seconds.coerceAtLeast(0L)
        val minutes = safeSeconds / 60L
        val remaining = safeSeconds % 60L
        return if (minutes > 0L) {
            String.format(Locale.US, "%d:%02d", minutes, remaining)
        } else {
            "${remaining}s"
        }
    }

    private fun readRemainingSeconds(data: Map<String, Any?>): Long? {
        val remaining = (data["foxgo_offer_remaining_seconds"]
            ?: data["foxgoOfferRemainingSeconds"]
            ?: data["remainingSeconds"])?.toString()?.trim()

        val parsedRemaining = remaining?.toDoubleOrNull()?.toLong()
        if (parsedRemaining != null) {
            return parsedRemaining
        }

        val expiresAt = (data["foxgo_offer_expires_at"]
            ?: data["foxgoOfferExpiresAt"]
            ?: data["expiresAt"])?.toString()?.trim()

        return secondsUntil(expiresAt)
    }

    private fun secondsUntil(rawExpiresAt: String?): Long? {
        if (rawExpiresAt.isNullOrBlank()) {
            return null
        }

        val patterns = listOf(
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        )

        for (pattern in patterns) {
            try {
                val formatter = SimpleDateFormat(pattern, Locale.US)
                if (pattern.contains("'Z'")) {
                    formatter.timeZone = TimeZone.getTimeZone("UTC")
                }
                val expiresAt = formatter.parse(rawExpiresAt)?.time ?: continue
                return ((expiresAt - System.currentTimeMillis()) / 1000L)
            } catch (_: Exception) {
            }
        }

        return null
    }

    private fun expireCurrentCall() {
        val expiredData = currentData + mapOf(
            "callId" to currentCallId,
            "expired" to true,
            "reason" to "expired"
        )
        onAction("onNewCallDismissed", expiredData)
        dismiss(notify = false)
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
        val tipo = when {
            ride -> "Corrida"
            rawType.contains("food") -> "Food"
            rawType.contains("pharmacy") || rawType.contains("farm") -> "Farmácia"
            rawType.contains("grocery") || rawType.contains("market") || rawType.contains("mercado") -> "Mercado"
            rawType.contains("parcel") || rawType.contains("encomenda") -> "Entrega"
            else -> "Entrega"
        }

        val title = "Entrega | $tipo"

        val origin = data["originName"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando detalhes"
        val pickup = data["pickupAddress"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando endereço de retirada"
        val destination = data["destinationAddress"]?.toString().takeUnless { it.isNullOrBlank() } ?: "Aguardando destino"
        val earning = data["earning"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val distance = data["distance"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val payment = data["paymentMethod"]?.toString().takeUnless { it.isNullOrBlank() } ?: "A confirmar"
        val paymentLower = payment.lowercase()
        val paymentChip = when {
            paymentLower.contains("cash") || paymentLower.contains("cod") || paymentLower.contains("dinheiro") -> "Dinheiro"
            paymentLower.contains("pix") -> "Pix"
            paymentLower.contains("card") || paymentLower.contains("cart") -> "Cartão"
            paymentLower.contains("online") || paymentLower.contains("digital") || paymentLower.contains("stripe") || paymentLower.contains("efi") || paymentLower.contains("pago") -> "Pago pelo app"
            payment == "A confirmar" -> "Pagamento a confirmar"
            else -> payment
        }

        val estimatedRaw = (
            data["estimatedTime"]
                ?: data["estimated_time"]
                ?: data["duration"]
                ?: data["durationText"]
                ?: data["eta"]
                ?: data["time"]
        )?.toString()?.trim().takeUnless { it.isNullOrBlank() }

        val estimatedTime = when {
            estimatedRaw.isNullOrBlank() -> "A confirmar"
            estimatedRaw.contains("≈") -> estimatedRaw
            estimatedRaw.lowercase().contains("min") -> "≈ $estimatedRaw"
            estimatedRaw.toDoubleOrNull() != null -> "≈ ${estimatedRaw.toDouble().toInt()} min"
            else -> estimatedRaw
        }

        view.findViewById<TextView>(R.id.tvTitle).text = title
        view.findViewById<TextView>(R.id.tvType).text = tipo
        view.findViewById<TextView>(R.id.tvPaymentChip).text = paymentChip
        view.findViewById<TextView>(R.id.tvDistanceChip).text = distance
        view.findViewById<TextView>(R.id.tvEstimatedTime).text = estimatedTime
        view.findViewById<TextView>(R.id.tvOrigin).text = "Origem / Retirada\n$origin"
        view.findViewById<TextView>(R.id.tvPickup).text = pickup
        view.findViewById<TextView>(R.id.tvDestination).text = "Destino\n$destination"
        view.findViewById<TextView>(R.id.tvEarning).text = "Você recebe\n$earning"
        view.findViewById<TextView>(R.id.tvDistance).text = "Distância: $distance"
        view.findViewById<TextView>(R.id.tvPayment).text = "Pagamento: $payment"

        val btnReject = view.findViewById<Button>(R.id.btnReject)
        val btnAccept = view.findViewById<Button>(R.id.btnAccept)

        btnReject.text = when {
            acceptConfirmPending -> "Voltar"
            rejectConfirmPending -> "Confirmar recusa"
            else -> "Recusar"
        }
        btnAccept.text = when {
            rejectConfirmPending -> "Voltar"
            acceptConfirmPending -> "Confirmar aceite"
            else -> "Aceitar"
        }

        when {
            acceptConfirmPending -> {
                btnReject.setBackgroundResource(R.drawable.foxgo_overlay_btn_back_bg)
                btnReject.setTextColor(Color.parseColor("#2D343A"))
                btnAccept.setBackgroundResource(R.drawable.foxgo_overlay_btn_accept_bg)
                btnAccept.setTextColor(Color.parseColor("#FFFFFFFF"))
            }
            rejectConfirmPending -> {
                btnReject.setBackgroundResource(R.drawable.foxgo_overlay_btn_reject_bg)
                btnReject.setTextColor(Color.parseColor("#B3261E"))
                btnAccept.setBackgroundResource(R.drawable.foxgo_overlay_btn_back_bg)
                btnAccept.setTextColor(Color.parseColor("#2D343A"))
            }
            else -> {
                btnReject.setBackgroundResource(R.drawable.foxgo_overlay_btn_reject_bg)
                btnReject.setTextColor(Color.parseColor("#B3261E"))
                btnAccept.setBackgroundResource(R.drawable.foxgo_overlay_btn_accept_bg)
                btnAccept.setTextColor(Color.parseColor("#FFFFFFFF"))
            }
        }

        val remainingSeconds = readRemainingSeconds(data)
        view.findViewById<TextView>(R.id.tvCountdown).text = if (remainingSeconds == null) {
            "Tempo: aguardando"
        } else if (remainingSeconds <= 0L) {
            "Chamada expirada"
        } else {
            "Tempo restante: ${formatSeconds(remainingSeconds)}"
        }
    }
}
