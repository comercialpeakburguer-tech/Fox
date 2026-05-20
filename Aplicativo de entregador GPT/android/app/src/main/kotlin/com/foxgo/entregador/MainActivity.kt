package com.foxgo.entregador

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.foxgo.entregador/call_permissions"
    private var overlayManager: NewCallOverlayManager? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        overlayManager = NewCallOverlayManager(this) { method, data ->
            runOnUiThread {
                methodChannel?.invokeMethod(method, data)
            }
        }

        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "openOverlaySettings" -> {
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "isFullScreenIntentAvailable" -> {
                    // Full-screen intent é complementar; Android 14+ pode restringir por política do sistema.
                    val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val manager = getSystemService(android.app.NotificationManager::class.java)
                        manager?.canUseFullScreenIntent() ?: false
                    } else {
                        true
                    }
                    result.success(allowed)
                }
                "openBatterySettings" -> {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:$packageName")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "showNewCallOverlay" -> {
                    val data = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() } ?: emptyMap<String, Any?>()
                    result.success(overlayManager?.show(data) ?: false)
                }
                "updateNewCallOverlay" -> {
                    val data = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() } ?: emptyMap<String, Any?>()
                    result.success(overlayManager?.update(data) ?: false)
                }
                "dismissNewCallOverlay" -> {
                    overlayManager?.dismiss()
                    result.success(true)
                }
                "isOverlayShowing" -> {
                    result.success(overlayManager?.isShowing() ?: false)
                }
                else -> result.notImplemented()
            }
        }
    }
}
