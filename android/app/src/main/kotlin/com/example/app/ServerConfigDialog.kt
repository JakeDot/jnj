package com.example.app

import android.app.Dialog
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.widget.SwitchCompat
import com.google.android.material.textfield.TextInputEditText

class ServerConfigDialog(
    private val context: Context,
    private val configManager: ServerConfigManager,
    private val onConfigSaved: (reloaded: Boolean) -> Unit
) {

    private val mainHandler = Handler(Looper.getMainLooper())

    fun show() {
        val view = LayoutInflater.from(context).inflate(R.layout.dialog_server_config, null)

        val rgHostingMode = view.findViewById<RadioGroup>(R.id.rgHostingMode)
        val rbSelfHosted = view.findViewById<RadioButton>(R.id.rbSelfHosted)
        val rbRemoteServer = view.findViewById<RadioButton>(R.id.rbRemoteServer)
        val rbNativeFlutter = view.findViewById<RadioButton>(R.id.rbNativeFlutter)

        val containerRemoteSettings = view.findViewById<View>(R.id.containerRemoteSettings)
        val etRemoteUrl = view.findViewById<TextInputEditText>(R.id.etRemoteUrl)
        val btnPresetEmulator = view.findViewById<Button>(R.id.btnPresetEmulator)
        val btnPresetLocalhost = view.findViewById<Button>(R.id.btnPresetLocalhost)
        val btnPresetGitHubPages = view.findViewById<Button>(R.id.btnPresetGitHubPages)
        val btnTestConnection = view.findViewById<Button>(R.id.btnTestConnection)
        val tvTestStatus = view.findViewById<TextView>(R.id.tvTestStatus)
        val switchAutoFallback = view.findViewById<SwitchCompat>(R.id.switchAutoFallback)

        val containerLocalSettings = view.findViewById<View>(R.id.containerLocalSettings)
        val etLocalPort = view.findViewById<TextInputEditText>(R.id.etLocalPort)

        val btnCancel = view.findViewById<Button>(R.id.btnCancel)
        val btnSaveApply = view.findViewById<Button>(R.id.btnSaveApply)

        // Initialize values
        when (configManager.activeMode) {
            HostingMode.SELF_HOSTED -> rbSelfHosted.isChecked = true
            HostingMode.REMOTE_SERVER -> rbRemoteServer.isChecked = true
            HostingMode.NATIVE_FLUTTER -> rbNativeFlutter.isChecked = true
        }

        etRemoteUrl.setText(configManager.remoteServerUrl)
        etLocalPort.setText(configManager.localServerPort.toString())
        switchAutoFallback.isChecked = configManager.autoFallback

        fun updateVisibility() {
            if (rbRemoteServer.isChecked) {
                containerRemoteSettings.visibility = View.VISIBLE
            } else {
                containerRemoteSettings.visibility = View.GONE
            }

            if (rbSelfHosted.isChecked) {
                containerLocalSettings.visibility = View.VISIBLE
            } else {
                containerLocalSettings.visibility = View.GONE
            }
        }

        updateVisibility()

        rgHostingMode.setOnCheckedChangeListener { _, _ ->
            updateVisibility()
        }

        btnPresetEmulator.setOnClickListener {
            etRemoteUrl.setText("http://10.0.2.2:8080")
        }

        btnPresetLocalhost.setOnClickListener {
            etRemoteUrl.setText("http://127.0.0.1:8080")
        }

        btnPresetGitHubPages.setOnClickListener {
            etRemoteUrl.setText("https://JakeDot.github.io/jnj/")
        }

        btnTestConnection.setOnClickListener {
            val urlStr = etRemoteUrl.text?.toString() ?: ""
            tvTestStatus.visibility = View.VISIBLE
            tvTestStatus.text = "Testing connection to $urlStr..."
            tvTestStatus.setTextColor(0xFF89B4FA.toInt())

            configManager.testConnection(urlStr) { success, _, message ->
                mainHandler.post {
                    tvTestStatus.text = message
                    if (success) {
                        tvTestStatus.setTextColor(0xFF00E5FF.toInt())
                    } else {
                        tvTestStatus.setTextColor(0xFFFF5555.toInt())
                    }
                }
            }
        }

        val dialog = AlertDialog.Builder(context, R.style.AppTheme)
            .setView(view)
            .setCancelable(true)
            .create()

        btnCancel.setOnClickListener {
            dialog.dismiss()
        }

        btnSaveApply.setOnClickListener {
            val selectedMode = when {
                rbRemoteServer.isChecked -> HostingMode.REMOTE_SERVER
                rbNativeFlutter.isChecked -> HostingMode.NATIVE_FLUTTER
                else -> HostingMode.SELF_HOSTED
            }

            val newRemoteUrl = etRemoteUrl.text?.toString() ?: ServerConfigManager.DEFAULT_REMOTE_URL
            val newLocalPort = etLocalPort.text?.toString()?.toIntOrNull() ?: ServerConfigManager.DEFAULT_LOCAL_PORT

            configManager.activeMode = selectedMode
            configManager.remoteServerUrl = newRemoteUrl
            configManager.localServerPort = newLocalPort
            configManager.autoFallback = switchAutoFallback.isChecked

            Toast.makeText(context, "Server configuration updated.", Toast.LENGTH_SHORT).show()
            dialog.dismiss()
            onConfigSaved(true)
        }

        dialog.show()
    }
}
