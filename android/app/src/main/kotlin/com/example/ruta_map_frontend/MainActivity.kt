package com.example.ruta_map_frontend

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CALL_CHANNEL = "com.example.ruta_map_frontend/call_state"
    private val USAGE_CHANNEL = "com.example.ruta_map_frontend/usage_stats"
    private var telephonyManager: TelephonyManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        // EventChannel: estados de llamada (ya lo tenías)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var listener: PhoneStateListener? = null
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null || telephonyManager == null) return
                    listener = object : PhoneStateListener() {
                        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                            when (state) {
                                TelephonyManager.CALL_STATE_RINGING -> events.success("RINGING")
                                TelephonyManager.CALL_STATE_OFFHOOK -> events.success("OFFHOOK")
                                TelephonyManager.CALL_STATE_IDLE -> events.success("IDLE")
                            }
                        }
                    }
                    @Suppress("DEPRECATION")
                    telephonyManager?.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
                }
                override fun onCancel(arguments: Any?) {
                    @Suppress("DEPRECATION")
                    telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
                    listener = null
                }
            })

        // MethodChannel: UsageStats (apps en foreground)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> {
                        result.success(hasUsagePermission())
                    }
                    "openSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "queryForegroundCount" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            val start = (args?.get("start") as? Number)?.toLong() ?: 0L
                            val end = (args?.get("end") as? Number)?.toLong() ?: 0L
                            val count = queryForegroundCount(start, end)
                            result.success(count)
                        } catch (e: Exception) {
                            result.error("QUERY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsagePermission(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    applicationContext.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    applicationContext.packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun queryForegroundCount(start: Long, end: Long): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return 0
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(start, end)
        val own = applicationContext.packageName
        val excluded = setOf(
            own,
            "android",
            "com.android.systemui",
            "com.google.android.inputmethod.latin",
            "com.samsung.android.honeyboard",
            "com.sec.android.inputmethod",
            "com.google.android.dialer",
            "com.android.launcher",
            "com.google.android.apps.nexuslauncher"
        )
        val set = HashSet<String>()
        val ev = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(ev)
            if (ev.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                val pkg = ev.packageName ?: continue
                if (!excluded.contains(pkg) && !pkg.startsWith("com.android")) {
                    set.add(pkg)
                }
            }
        }
        return set.size
    }
}
