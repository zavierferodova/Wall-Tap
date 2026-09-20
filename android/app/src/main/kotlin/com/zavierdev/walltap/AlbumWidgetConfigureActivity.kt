package com.zavierdev.walltap

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ImageView
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import org.json.JSONArray

class AlbumWidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var btnClose: ImageView
    private lateinit var spinnerAlbum: Spinner
    private lateinit var spinnerInterval: Spinner
    private lateinit var radioGroupOrder: RadioGroup
    private lateinit var radioOrdered: RadioButton
    private lateinit var radioRandom: RadioButton
    private lateinit var btnShuffleNow: Button
    private lateinit var btnSave: Button
    private lateinit var btnOpenApp: TextView

    private val albumOptions = mutableListOf<Pair<String, String>>()
    private val intervalOptions = listOf(
        Pair(0, "Manual / Static (No Rotation)"),
        Pair(1, "Every 1 minute"),
        Pair(5, "Every 5 minutes"),
        Pair(15, "Every 15 minutes"),
        Pair(30, "Every 30 minutes"),
        Pair(60, "Every 1 hour"),
        Pair(180, "Every 3 hours"),
        Pair(360, "Every 6 hours"),
        Pair(1440, "Every 24 hours (Daily)")
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.statusBarColor = 0xFF0D0E12.toInt()
            window.navigationBarColor = 0xFF0D0E12.toInt()
        }

        setContentView(R.layout.activity_album_widget_configure)

        val root = findViewById<View>(R.id.configure_root)
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, windowInsets ->
            val insets = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            val density = resources.displayMetrics.density
            val padX = (20 * density).toInt()
            val padTop = (16 * density).toInt()
            val padBottom = (16 * density).toInt()

            v.setPadding(
                padX + insets.left,
                insets.top + padTop,
                padX + insets.right,
                insets.bottom + padBottom
            )
            windowInsets
        }

        btnClose = findViewById(R.id.btn_close)
        spinnerAlbum = findViewById(R.id.spinner_album)
        spinnerInterval = findViewById(R.id.spinner_interval)
        radioGroupOrder = findViewById(R.id.radio_group_order)
        radioOrdered = findViewById(R.id.radio_ordered)
        radioRandom = findViewById(R.id.radio_random)
        btnShuffleNow = findViewById(R.id.btn_shuffle_now)
        btnSave = findViewById(R.id.btn_save_widget)
        btnOpenApp = findViewById(R.id.btn_open_app)

        loadAlbums()
        setupIntervalSpinner()
        restoreCurrentConfiguration()

        btnClose.setOnClickListener {
            finish()
        }

        btnShuffleNow.setOnClickListener {
            AlbumWidgetProvider.advanceWidget(this, appWidgetId)
            Toast.makeText(this, "Shuffled to next photo", Toast.LENGTH_SHORT).show()
        }

        btnOpenApp.setOnClickListener {
            val appIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(appIntent)
            finish()
        }

        btnSave.setOnClickListener {
            saveWidgetConfiguration()
        }
    }

    private fun loadAlbums() {
        albumOptions.clear()
        albumOptions.add(Pair("all_photos", "All Photos (Full Gallery)"))

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val albumsJson = prefs.getString("flutter.walltap_albums", null)
        if (!albumsJson.isNullOrEmpty()) {
            try {
                val array = JSONArray(albumsJson)
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    val id = obj.optString("id")
                    val name = obj.optString("name")
                    val count = obj.optJSONArray("wallpaperIds")?.length() ?: 0
                    if (id.isNotEmpty() && name.isNotEmpty()) {
                        albumOptions.add(Pair(id, "$name ($count photos)"))
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        val albumNames = albumOptions.map { it.second }
        val adapter = object : ArrayAdapter<String>(this, R.layout.widget_spinner_item, albumNames) {
            override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = super.getDropDownView(position, convertView, parent)
                if (view is TextView) {
                    view.setTextColor(0xFFFFFFFF.toInt())
                    view.setBackgroundColor(0xFF1E2130.toInt())
                }
                return view
            }
        }
        spinnerAlbum.adapter = adapter
    }

    private fun setupIntervalSpinner() {
        val intervalLabels = intervalOptions.map { it.second }
        val adapter = object : ArrayAdapter<String>(this, R.layout.widget_spinner_item, intervalLabels) {
            override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = super.getDropDownView(position, convertView, parent)
                if (view is TextView) {
                    view.setTextColor(0xFFFFFFFF.toInt())
                    view.setBackgroundColor(0xFF1E2130.toInt())
                }
                return view
            }
        }
        spinnerInterval.adapter = adapter
    }

    private fun restoreCurrentConfiguration() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isExisting = prefs.contains("flutter.album_widget_${appWidgetId}_album_id")
        val savedAlbumId = prefs.getString("flutter.album_widget_${appWidgetId}_album_id", null)
        val savedInterval = prefs.getLong("flutter.album_widget_${appWidgetId}_interval_minutes", 15L).toInt()
        val savedIsRandom = prefs.getBoolean("flutter.album_widget_${appWidgetId}_is_random", true)

        if (isExisting) {
            btnSave.text = "Save Settings"
            btnShuffleNow.visibility = View.VISIBLE

            if (savedAlbumId != null) {
                val albumIndex = albumOptions.indexOfFirst { it.first == savedAlbumId }
                if (albumIndex >= 0) {
                    spinnerAlbum.setSelection(albumIndex)
                }
            }

            val intervalIndex = intervalOptions.indexOfFirst { it.first == savedInterval }
            if (intervalIndex >= 0) {
                spinnerInterval.setSelection(intervalIndex)
            } else {
                spinnerInterval.setSelection(3) // 15 minutes default
            }

            if (savedIsRandom) {
                radioRandom.isChecked = true
            } else {
                radioOrdered.isChecked = true
            }
        } else {
            btnSave.text = "Apply & Add Widget"
            btnShuffleNow.visibility = View.GONE
            radioRandom.isChecked = true
            spinnerInterval.setSelection(3) // 15 minutes default
        }
    }

    private fun saveWidgetConfiguration() {
        val selectedAlbumIndex = spinnerAlbum.selectedItemPosition.coerceIn(0, albumOptions.size - 1)
        val selectedAlbum = albumOptions[selectedAlbumIndex]
        val albumId = selectedAlbum.first
        val rawName = selectedAlbum.second.substringBeforeLast(" (")
        val albumName = if (albumId == "all_photos") "All Photos" else rawName

        val isRandom = radioRandom.isChecked

        val selectedIntervalIndex = spinnerInterval.selectedItemPosition.coerceIn(0, intervalOptions.size - 1)
        val intervalMinutes = intervalOptions[selectedIntervalIndex].first

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("flutter.album_widget_${appWidgetId}_album_id", albumId)
            .putString("flutter.album_widget_${appWidgetId}_album_name", albumName)
            .putLong("flutter.album_widget_${appWidgetId}_interval_minutes", intervalMinutes.toLong())
            .putBoolean("flutter.album_widget_${appWidgetId}_is_random", isRandom)
            .putLong("flutter.album_widget_${appWidgetId}_current_index", 0L)
            .apply()

        // Render widget immediately
        val appWidgetManager = AppWidgetManager.getInstance(this)
        AlbumWidgetProvider.updateWidget(this, appWidgetManager, appWidgetId)

        // Schedule rotation if interval > 0
        AlbumWidgetScheduler.schedule(this, appWidgetId, intervalMinutes)

        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultValue)
        finish()
    }
}
