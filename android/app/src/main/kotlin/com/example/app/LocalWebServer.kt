package com.example.app

import android.content.Context
import android.util.Log
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import com.sun.net.httpserver.HttpServer
import java.io.InputStream
import java.net.InetSocketAddress
import java.util.concurrent.Executors

class LocalWebServer(private val context: Context, private val port: Int = 8080) {

    private var server: HttpServer? = null
    private val TAG = "LocalWebServer"

    @Synchronized
    fun start(): Boolean {
        if (server != null) return true

        try {
            server = HttpServer.create(InetSocketAddress("127.0.0.1", port), 0)
            server?.createContext("/", AssetHandler())
            server?.executor = Executors.newCachedThreadPool()
            server?.start()
            Log.i(TAG, "Local Web Server started successfully on http://127.0.0.1:$port")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Local Web Server on port $port", e)
            server = null
            return false
        }
    }

    @Synchronized
    fun stop() {
        try {
            server?.stop(0)
            server = null
            Log.i(TAG, "Local Web Server stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Local Web Server", e)
        }
    }

    private inner class AssetHandler : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            try {
                var path = exchange.requestURI.path
                if (path == "/" || path.isEmpty()) {
                    path = "/index.html"
                }

                val cleanPath = if (path.startsWith("/")) path.substring(1) else path
                val fileName = cleanPath.substringAfterLast("/")

                var inputStream: InputStream? = null
                var resolvedAssetPath = "web/$cleanPath"

                // Attempt 1: Try direct asset path (web/cleanPath)
                try {
                    inputStream = context.assets.open(resolvedAssetPath)
                } catch (_: Exception) {
                    // Attempt 2: Try filename directly inside web/
                    if (fileName.isNotEmpty()) {
                        try {
                            resolvedAssetPath = "web/$fileName"
                            inputStream = context.assets.open(resolvedAssetPath)
                        } catch (_: Exception) {}
                    }
                }

                // Attempt 3: Fallback to index.html for Single Page Application routing
                if (inputStream == null) {
                    try {
                        resolvedAssetPath = "web/index.html"
                        inputStream = context.assets.open(resolvedAssetPath)
                    } catch (_: Exception) {
                        val notFoundMsg = "404 Not Found"
                        exchange.sendResponseHeaders(404, notFoundMsg.length.toLong())
                        exchange.responseBody.use { it.write(notFoundMsg.toByteArray()) }
                        return
                    }
                }

                val mimeType = getMimeType(resolvedAssetPath)

                val bytes = inputStream.readBytes()
                inputStream.close()

                // Add CORS & Cache Control headers
                exchange.responseHeaders.add("Access-Control-Allow-Origin", "*")
                exchange.responseHeaders.add("Content-Type", mimeType)
                exchange.responseHeaders.add("Cache-Control", "no-cache, no-store, must-revalidate")

                exchange.sendResponseHeaders(200, bytes.size.toLong())
                exchange.responseBody.use { os ->
                    os.write(bytes)
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error serving web asset", e)
                try {
                    val errMsg = "500 Internal Server Error"
                    exchange.sendResponseHeaders(500, errMsg.length.toLong())
                    exchange.responseBody.use { it.write(errMsg.toByteArray()) }
                } catch (_: Exception) {}
            }
        }

        private fun getMimeType(path: String): String {
            return when {
                path.endsWith(".html", ignoreCase = true) -> "text/html; charset=UTF-8"
                path.endsWith(".js", ignoreCase = true) -> "application/javascript; charset=UTF-8"
                path.endsWith(".css", ignoreCase = true) -> "text/css; charset=UTF-8"
                path.endsWith(".json", ignoreCase = true) -> "application/json"
                path.endsWith(".wasm", ignoreCase = true) -> "application/wasm"
                path.endsWith(".png", ignoreCase = true) -> "image/png"
                path.endsWith(".jpg", ignoreCase = true) || path.endsWith(".jpeg", ignoreCase = true) -> "image/jpeg"
                path.endsWith(".svg", ignoreCase = true) -> "image/svg+xml"
                path.endsWith(".ico", ignoreCase = true) -> "image/x-icon"
                path.endsWith(".ttf", ignoreCase = true) -> "font/ttf"
                path.endsWith(".woff", ignoreCase = true) -> "font/woff"
                path.endsWith(".woff2", ignoreCase = true) -> "font/woff2"
                else -> "application/octet-stream"
            }
        }
    }
}
