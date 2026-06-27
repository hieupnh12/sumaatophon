package com.example.sumaatophon

import android.os.Build
import android.os.Debug
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.sumaatophon/debug"
    private var flutterSurfaceView: FlutterSurfaceView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDebuggerConnected" -> result.success(Debug.isDebuggerConnected())
                    "isEmulator" -> result.success(isEmulator())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onFlutterSurfaceViewCreated(flutterSurfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(flutterSurfaceView)
        this.flutterSurfaceView = flutterSurfaceView
        applyMaxRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        // MIUI hay reset refresh rate khi app resume hoặc sau tiết kiệm pin.
        applyMaxRefreshRate()
    }

    private fun applyMaxRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val display = display ?: return
        val currentMode = display.mode
        val targetMode = display.supportedModes
            .filter {
                it.physicalWidth == currentMode.physicalWidth &&
                    it.physicalHeight == currentMode.physicalHeight
            }
            .maxByOrNull { it.refreshRate }
            ?: return

        if (targetMode.refreshRate <= 60f) return

        window.attributes = window.attributes.also {
            it.preferredDisplayModeId = targetMode.modeId
            it.preferredRefreshRate = targetMode.refreshRate
        }

        if (Build.VERSION.SDK_INT >= 35) {
            try {
                window.setFrameRateBoostOnTouchEnabled(true)
                window.decorView.setRequestedFrameRate(
                    View.REQUESTED_FRAME_RATE_CATEGORY_HIGH.toFloat(),
                )
            } catch (_: Exception) {
            }
        }

        if (Build.VERSION.SDK_INT >= 35) {
            try {
                flutterSurfaceView?.setRequestedFrameRate(
                    View.REQUESTED_FRAME_RATE_CATEGORY_HIGH.toFloat(),
                )
            } catch (_: Exception) {
            }
        }
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic")
            || Build.FINGERPRINT.startsWith("unknown")
            || Build.FINGERPRINT.contains("emulator", ignoreCase = true)
            || Build.FINGERPRINT.contains("sdk_gphone", ignoreCase = true)
            || Build.MODEL.contains("google_sdk", ignoreCase = true)
            || Build.MODEL.contains("Emulator", ignoreCase = true)
            || Build.MODEL.contains("Android SDK built for x86", ignoreCase = true)
            || Build.MODEL.contains("sdk_gphone", ignoreCase = true)
            || Build.HARDWARE.contains("goldfish", ignoreCase = true)
            || Build.HARDWARE.contains("ranchu", ignoreCase = true)
            || Build.PRODUCT.contains("sdk_gphone", ignoreCase = true)
            || Build.PRODUCT.contains("emulator", ignoreCase = true)
            || Build.MANUFACTURER.contains("Genymotion", ignoreCase = true)
            || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
            || Build.PRODUCT == "google_sdk"
    }
}
