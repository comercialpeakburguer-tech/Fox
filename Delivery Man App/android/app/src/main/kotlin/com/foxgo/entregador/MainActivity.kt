package com.foxgo.entregador

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.os.PowerManager
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
                val callbackAvailable = methodChannel != null
                android.util.Log.i("FoxGoCallAction", "overlay Activity action=$method callbackFlutterDisponivel=$callbackAvailable payload=$data orderId=${detectOrderId(data)}")
                try {
                    methodChannel?.invokeMethod(method, data)
                } catch (exception: Exception) {
                    android.util.Log.e("FoxGoCallAction", "erro ao entregar clique do overlay para Flutter action=$method orderId=${detectOrderId(data)}", exception)
                }
            }
        }

        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "openOverlaySettings" -> {
                    result.success(openOverlaySettingsSmart())
                }
                "openOverlaySettingsSmart" -> {
                    result.success(openOverlaySettingsSmart())
                }
                "isIgnoringBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "openBatteryOptimizationSettingsSmart" -> {
                    result.success(openBatteryOptimizationSettingsSmart())
                }
                "openAppLocationSettings" -> {
                    result.success(openAppLocationSettings())
                }
                "getDeviceInfo" -> {
                    result.success(mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "brand" to Build.BRAND,
                        "model" to Build.MODEL,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "release" to Build.VERSION.RELEASE
                    ))
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
                "startOnlineForegroundService" -> {
                    result.success(FoxGoOnlineService.start(this))
                }
                "stopOnlineForegroundService" -> {
                    result.success(FoxGoOnlineService.stop(this))
                }
                "isOnlineForegroundServiceRunning" -> {
                    result.success(FoxGoOnlineService.isRunning)
                }
                "openBatterySettings" -> {
                    result.success(openBatteryOptimizationSettingsSmart())
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
                    result.success(startOverlayService(NewCallOverlayService.ACTION_SHOW, data))
                }
                "updateNewCallOverlay" -> {
                    val data = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() } ?: emptyMap<String, Any?>()
                    result.success(startOverlayService(NewCallOverlayService.ACTION_UPDATE, data))
                }
                "dismissNewCallOverlay" -> {
                    startOverlayService(NewCallOverlayService.ACTION_DISMISS, emptyMap())
                    overlayManager?.dismiss()
                    result.success(true)
                }
                "isOverlayShowing" -> {
                    result.success(NewCallOverlayService.isShowing || (overlayManager?.isShowing() ?: false))
                }
                "showNewCallFallback" -> {
                    val data = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() } ?: emptyMap<String, Any?>()
                    result.success(FoxGoCallFallbackNotifier.show(this, data, source = "flutter-method-channel"))
                }
                else -> result.notImplemented()
            }
        }
    }


    private fun isDebugBuild(): Boolean {
        return (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun openOverlaySettingsSmart(): Boolean {
        if (isDebugBuild()) android.util.Log.d("FoxGoOverlayPermission", "manufacturer=${Build.MANUFACTURER} brand=${Build.BRAND} model=${Build.MODEL} sdk=${Build.VERSION.SDK_INT}")
        val packageUri = Uri.parse("package:$packageName")
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val candidates = mutableListOf<Intent>()

        candidates += Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, packageUri)
        when {
            manufacturer.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                candidates += Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                    setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity")
                    putExtra("extra_pkgname", packageName)
                }
                candidates += Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                    setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.AppPermissionsEditorActivity")
                    putExtra("extra_pkgname", packageName)
                }
            }
            manufacturer.contains("huawei") || brand.contains("honor") -> {
                candidates += Intent().apply { component = ComponentName("com.huawei.systemmanager", "com.huawei.permissionmanager.ui.MainActivity") }
            }
            manufacturer.contains("oppo") || manufacturer.contains("realme") || manufacturer.contains("oneplus") -> {
                candidates += Intent().apply { component = ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.floatwindow.FloatWindowListActivity") }
                candidates += Intent().apply { component = ComponentName("com.coloros.safecenter", "com.coloros.safecenter.sysfloatwindow.FloatWindowListActivity") }
            }
            manufacturer.contains("vivo") -> {
                candidates += Intent().apply { component = ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity"); putExtra("packagename", packageName) }
            }
            manufacturer.contains("samsung") || manufacturer.contains("motorola") -> {
                // Samsung e Motorola seguem majoritariamente o intent padrão do Android; mantemos fallback abaixo.
            }
        }
        candidates += Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
        candidates += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
        return startFirstAvailable(candidates, "FoxGoOverlayPermission")
    }

    private fun openBatteryOptimizationSettingsSmart(): Boolean {
        if (isDebugBuild()) android.util.Log.d("FoxGoBatteryPermission", "manufacturer=${Build.MANUFACTURER} brand=${Build.BRAND} model=${Build.MODEL} sdk=${Build.VERSION.SDK_INT}")
        val packageUri = Uri.parse("package:$packageName")
        val candidates = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            candidates += Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, packageUri)
            candidates += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        }
        candidates += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
        return startFirstAvailable(candidates, "FoxGoBatteryPermission")
    }

    private fun openAppLocationSettings(): Boolean {
        val packageUri = Uri.parse("package:$packageName")
        val candidates = listOf(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri),
            Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
        )
        return startFirstAvailable(candidates, "FoxGoPermissionFlow")
    }

    private fun startFirstAvailable(intents: List<Intent>, logTag: String): Boolean {
        for (candidate in intents) {
            try {
                candidate.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(candidate)
                return true
            } catch (e: ActivityNotFoundException) {
                if (isDebugBuild()) android.util.Log.w(logTag, "Intent indisponível: ${candidate.action} ${candidate.component}", e)
            } catch (e: Exception) {
                if (isDebugBuild()) android.util.Log.w(logTag, "Falha ao abrir configuração: ${candidate.action} ${candidate.component}", e)
            }
        }
        return false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        forwardOverlayIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        forwardOverlayIntent(intent)
    }

    private fun forwardOverlayIntent(intent: Intent?) {
        val action = intent?.getStringExtra(NewCallOverlayService.EXTRA_OVERLAY_ACTION) ?: return
        val data = mutableMapOf<String, Any?>()
        intent.extras?.keySet()?.forEach { key -> data[key] = intent.extras?.get(key) }
        val callbackAvailable = methodChannel != null
        val orderId = detectOrderId(data)
        android.util.Log.i("FoxGoCallAction", "ação $action recebida no MainActivity payload=$data orderId=$orderId callId=${data[NewCallOverlayService.EXTRA_CALL_ID]} callbackFlutterDisponivel=$callbackAvailable")
        if (!callbackAvailable) {
            android.util.Log.w("FoxGoCallAction", "Flutter callback indisponível; mantendo action no intent para tentar no onResume orderId=$orderId")
            return
        }
        try {
            methodChannel?.invokeMethod(action, data)
            android.util.Log.i("FoxGoCallAction", "ação entregue para Flutter action=$action orderId=$orderId")
            intent.removeExtra(NewCallOverlayService.EXTRA_OVERLAY_ACTION)
        } catch (exception: Exception) {
            android.util.Log.e("FoxGoCallAction", "erro ao encaminhar ação para Flutter action=$action orderId=$orderId", exception)
        }
    }

    private fun detectOrderId(data: Map<String, Any?>): String? {
        return listOf("orderId", "order_id", "id", "callId")
            .mapNotNull { key -> data[key]?.toString()?.takeIf { value -> value.isNotBlank() } }
            .firstOrNull()
    }

    private fun startOverlayService(action: String, data: Map<String, Any?>): Boolean {
        val canDraw = Settings.canDrawOverlays(this)
        android.util.Log.i("FoxGoOverlayService", "Settings.canDrawOverlays=$canDraw action=$action")
        if (action != NewCallOverlayService.ACTION_DISMISS && !canDraw) {
            FoxGoCallFallbackNotifier.show(this, data, source = "overlay-permission-denied")
            return false
        }
        return try {
            startOverlayFallbackService(action, data)
            android.util.Log.i("FoxGoOverlayService", "start service sucesso action=$action callId=${data["callId"]}")
            true
        } catch (exception: Exception) {
            android.util.Log.e("FoxGoOverlayService", "start service falha action=$action callId=${data["callId"]}", exception)
            FoxGoCallFallbackNotifier.show(this, data, source = "overlay-start-exception")
            false
        }
    }

    private fun startOverlayFallbackService(action: String, data: Map<String, Any?>) {
        val intent = Intent(this, NewCallOverlayService::class.java).apply {
            this.action = action
            data.forEach { (key, value) -> putExtraValue(key, value) }
        }
        android.util.Log.i("FoxGoOverlayService", "startService/startForegroundService chamado action=$action extras=${data.keys}")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
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
