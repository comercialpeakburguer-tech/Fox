package com.foxgo.entregador

import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

class FoxGoFirebaseMessagingService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        Log.i("FoxGoFCM", "native FCM entrou onMessageReceived keys=${message.data.keys} type=${message.data["type"]} messageType=${message.data["message_type"]} notificationType=${message.data["notification_type"]} orderId=${message.data["order_id"] ?: message.data["orderId"]} action=${message.data["action"]} data=${message.data}")
        FoxGoCallRouter.route(applicationContext, message.data, source = "native-fcm")
        super.onMessageReceived(message)
    }

    override fun onNewToken(token: String) {
        Log.i("FoxGoFCM", "native FCM token atualizado; repassando para FlutterFire")
        super.onNewToken(token)
    }
}
