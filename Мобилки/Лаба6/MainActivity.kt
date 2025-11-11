package com.example.lab_6

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.bluetooth.BluetoothAdapter
import android.net.Uri
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "travel/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val level = getBatteryLevel()
                    if (level != -1) result.success(level) else result.error("UNAVAILABLE", "Battery not available", null)
                }
                "getBluetoothStatus" -> {
                    val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null) result.success("NotSupported") else result.success(if (adapter.isEnabled) "Enabled" else "Disabled")
                }
                "openBrowser" -> {
                    val url: String? = call.argument("url")
                    if (url != null) {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID", "No URL provided", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = registerReceiver(null, ifilter)

        return batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    }
}
