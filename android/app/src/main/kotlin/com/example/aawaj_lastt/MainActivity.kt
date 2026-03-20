package com.example.aawaj_lastt

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "sos_volume_channel"
    private var pressCount = 0
    private var firstPressTime: Long = 0

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN &&
            event.keyCode == KeyEvent.KEYCODE_VOLUME_UP
        ) {
            handleVolumePress()
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private fun handleVolumePress() {
        val now = System.currentTimeMillis()

        if (pressCount == 0) {
            firstPressTime = now
        }

        pressCount++

        if (now - firstPressTime > 3000) {
            pressCount = 1
            firstPressTime = now
        }

        if (pressCount == 5) {
            MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                CHANNEL
            ).invokeMethod("SOS_TRIGGERED", null)

            pressCount = 0
        }
    }
}
