package com.example.app

import android.content.Context
import android.content.SharedPreferences
import java.net.HttpURLConnection
import java.net.URL

enum class HostingMode(val key: String) {
    SELF_HOSTED("self_hosted"),
    REMOTE_SERVER("remote_server"),
    NATIVE_FLUTTER("native_flutter");

    companion object {
        fun fromKey(key: String?): HostingMode {
            return entries.find { it.key.equals(key, ignoreCase = true) } ?: SELF_HOSTED
        }
    }
}

class ServerConfigManager(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var activeMode: HostingMode
        get() {
            val key = prefs.getString(KEY_ACTIVE_MODE, HostingMode.SELF_HOSTED.key)
            return HostingMode.fromKey(key)
        }
        set(value) {
            prefs.edit().putString(KEY_ACTIVE_MODE, value.key).apply()
        }

    var remoteServerUrl: String
        get() = prefs.getString(KEY_REMOTE_URL, DEFAULT_REMOTE_URL) ?: DEFAULT_REMOTE_URL
        set(value) {
            val normalized = normalizeUrl(value)
            prefs.edit().putString(KEY_REMOTE_URL, normalized).apply()
        }

    var localServerPort: Int
        get() = prefs.getInt(KEY_LOCAL_PORT, DEFAULT_LOCAL_PORT)
        set(value) {
            prefs.edit().putInt(KEY_LOCAL_PORT, value).apply()
        }

    var autoFallback: Boolean
        get() = prefs.getBoolean(KEY_AUTO_FALLBACK, true)
        set(value) {
            prefs.edit().putBoolean(KEY_AUTO_FALLBACK, value).apply()
        }

    fun getSelfHostedAssetUrl(): String {
        return "https://appassets.androidplatform.net/assets/web/index.html"
    }

    fun getLocalServerUrl(): String {
        return "http://127.0.0.1:$localServerPort/index.html"
    }

    fun getActiveUrl(): String {
        return when (activeMode) {
            HostingMode.SELF_HOSTED -> getSelfHostedAssetUrl()
            HostingMode.REMOTE_SERVER -> remoteServerUrl
            HostingMode.NATIVE_FLUTTER -> getSelfHostedAssetUrl()
        }
    }

    fun testConnection(targetUrl: String, onResult: (success: Boolean, latencyMs: Long, message: String) -> Unit) {
        Thread {
            val urlString = normalizeUrl(targetUrl)
            val startTime = System.currentTimeMillis()
            var connection: HttpURLConnection? = null
            try {
                val url = URL(urlString)
                connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = 4000
                connection.readTimeout = 4000
                connection.requestMethod = "GET"
                
                val responseCode = connection.responseCode
                val latency = System.currentTimeMillis() - startTime
                if (responseCode in 200..399) {
                    onResult(true, latency, "Connected ($responseCode) - ${latency}ms")
                } else {
                    onResult(false, latency, "Server returned HTTP $responseCode")
                }
            } catch (e: Exception) {
                val latency = System.currentTimeMillis() - startTime
                onResult(false, latency, "Connection failed: ${e.localizedMessage ?: "Timeout/Unreachable"}")
            } finally {
                connection?.disconnect()
            }
        }.start()
    }

    companion object {
        private const val PREFS_NAME = "jules_wrapper_config"
        private const val KEY_ACTIVE_MODE = "active_hosting_mode"
        private const val KEY_REMOTE_URL = "remote_server_url"
        private const val KEY_LOCAL_PORT = "local_server_port"
        private const val KEY_AUTO_FALLBACK = "auto_fallback"

        const val DEFAULT_REMOTE_URL = "http://10.0.2.2:8080"
        const val DEFAULT_LOCAL_PORT = 8080

        fun normalizeUrl(urlStr: String): String {
            var trimmed = urlStr.trim()
            if (trimmed.isEmpty()) return DEFAULT_REMOTE_URL
            if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
                trimmed = "http://$trimmed"
            }
            return trimmed
        }
    }
}
