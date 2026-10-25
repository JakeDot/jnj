package com.example.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.webkit.JavascriptInterface
import android.widget.Toast

class AndroidBridge(
    private val context: Context,
    private val configManager: ServerConfigManager,
    private val onOpenConfigRequested: () -> Unit,
    private val onReloadRequested: () -> Unit
) {

    private val mainHandler = Handler(Looper.getMainLooper())

    @JavascriptInterface
    fun getHostingMode(): String {
        return configManager.activeMode.name
    }

    @JavascriptInterface
    fun getRemoteServerUrl(): String {
        return configManager.remoteServerUrl
    }

    @JavascriptInterface
    fun getActiveUrl(): String {
        return configManager.getActiveUrl()
    }

    @JavascriptInterface
    fun openServerConfig() {
        mainHandler.post {
            onOpenConfigRequested()
        }
    }

    @JavascriptInterface
    fun reloadApp() {
        mainHandler.post {
            onReloadRequested()
        }
    }

    @JavascriptInterface
    fun showToast(message: String) {
        mainHandler.post {
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
        }
    }

    @JavascriptInterface
    fun isAndroidWrapper(): Boolean {
        return true
    }
}
