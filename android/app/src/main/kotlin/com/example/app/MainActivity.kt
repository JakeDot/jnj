package com.example.app

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Log
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import androidx.webkit.WebViewAssetLoader
import io.flutter.embedding.android.FlutterActivity

class MainActivity : AppCompatActivity() {

    private lateinit var configManager: ServerConfigManager
    private var localWebServer: LocalWebServer? = null

    private lateinit var toolbar: Toolbar
    private lateinit var progressBar: ProgressBar
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var webView: WebView
    private lateinit var layoutError: View
    private lateinit var tvErrorMessage: TextView
    private lateinit var btnRetry: Button
    private lateinit var btnFallbackSelfHosted: Button

    private lateinit var assetLoader: WebViewAssetLoader
    private val TAG = "JulesMainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main_wrapper)

        configManager = ServerConfigManager(this)

        initViews()
        setupLocalServer()
        setupAssetLoader()
        setupWebView()

        loadActiveServer()
    }

    private fun initViews() {
        toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)

        progressBar = findViewById(R.id.progressBar)
        swipeRefresh = findViewById(R.id.swipeRefresh)
        webView = findViewById(R.id.webView)
        layoutError = findViewById(R.id.layoutError)
        tvErrorMessage = findViewById(R.id.tvErrorMessage)
        btnRetry = findViewById(R.id.btnRetry)
        btnFallbackSelfHosted = findViewById(R.id.btnFallbackSelfHosted)

        swipeRefresh.setColorSchemeColors(0xFF00E5FF.toInt(), 0xFF89B4FA.toInt())
        swipeRefresh.setOnRefreshListener {
            loadActiveServer()
        }

        btnRetry.setOnClickListener {
            layoutError.visibility = View.GONE
            loadActiveServer()
        }

        btnFallbackSelfHosted.setOnClickListener {
            configManager.activeMode = HostingMode.SELF_HOSTED
            layoutError.visibility = View.GONE
            loadActiveServer()
        }
    }

    private fun setupLocalServer() {
        localWebServer = LocalWebServer(this, configManager.localServerPort)
        localWebServer?.start()
    }

    private fun setupAssetLoader() {
        assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.allowFileAccess = true
        settings.allowContentAccess = true
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW

        val bridge = AndroidBridge(
            context = this,
            configManager = configManager,
            onOpenConfigRequested = { showServerConfigDialog() },
            onReloadRequested = { loadActiveServer() }
        )
        webView.addJavascriptInterface(bridge, "AndroidBridge")

        webView.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(
                view: WebView?,
                request: WebResourceRequest?
            ) = request?.url?.let { assetLoader.shouldInterceptRequest(it) }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                progressBar.visibility = View.VISIBLE
                layoutError.visibility = View.GONE
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                progressBar.visibility = View.GONE
                swipeRefresh.isRefreshing = false
            }

            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                super.onReceivedError(view, request, error)
                if (request?.isForMainFrame == true) {
                    progressBar.visibility = View.GONE
                    swipeRefresh.isRefreshing = false

                    if (configManager.activeMode == HostingMode.REMOTE_SERVER && configManager.autoFallback) {
                        Toast.makeText(
                            this@MainActivity,
                            "Remote server unreachable. Auto-falling back to local self-hosted code.",
                            Toast.LENGTH_LONG
                        ).show()
                        configManager.activeMode = HostingMode.SELF_HOSTED
                        loadActiveServer()
                    } else {
                        layoutError.visibility = View.VISIBLE
                        tvErrorMessage.text = "Failed to load: ${error?.description ?: "Connection Error"}\nTarget: ${configManager.getActiveUrl()}"
                    }
                }
            }
        }
    }

    private fun loadActiveServer() {
        val mode = configManager.activeMode
        updateSubtitle()

        if (mode == HostingMode.NATIVE_FLUTTER) {
            val intent = FlutterActivity.createDefaultIntent(this)
            startActivity(intent)
            return
        }

        val targetUrl = configManager.getActiveUrl()
        Log.i(TAG, "Loading URL in WebView ($mode): $targetUrl")
        webView.loadUrl(targetUrl)
    }

    private fun updateSubtitle() {
        val subtitleText = when (configManager.activeMode) {
            HostingMode.SELF_HOSTED -> "Mode: Self-Hosted (Local)"
            HostingMode.REMOTE_SERVER -> "Mode: Remote (${configManager.remoteServerUrl})"
            HostingMode.NATIVE_FLUTTER -> "Mode: Native Engine"
        }
        supportActionBar?.subtitle = subtitleText
    }

    private fun showServerConfigDialog() {
        ServerConfigDialog(this, configManager) { reloaded ->
            if (reloaded) {
                if (configManager.activeMode == HostingMode.SELF_HOSTED) {
                    localWebServer?.stop()
                    setupLocalServer()
                }
                loadActiveServer()
            }
        }.show()
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.menu_wrapper, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_refresh -> {
                loadActiveServer()
                true
            }
            R.id.action_server_config -> {
                showServerConfigDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onDestroy() {
        localWebServer?.stop()
        super.onDestroy()
    }
}
