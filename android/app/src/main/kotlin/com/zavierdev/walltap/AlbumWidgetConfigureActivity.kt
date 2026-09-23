package com.zavierdev.walltap

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import org.json.JSONArray
import java.io.File
import kotlin.random.Random

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

    // Preview UI elements
    private lateinit var previewCardContainer: FrameLayout
    private lateinit var ivWidgetPreview: ImageView
    private lateinit var previewEmptyContainer: LinearLayout
    private lateinit var tvPreviewEmptyText: TextView
    private lateinit var previewInfoOverlay: LinearLayout
    private lateinit var tvPreviewAlbumTitle: TextView
    private lateinit var tvPreviewBadge: TextView
    private lateinit var tvPreviewCounter: TextView

    private val albumOptions = mutableListOf<Pair<String, String>>()
    private val intervalOptions = listOf(
        Pair(0, "Manual / Static (No Rotation)"),
        Pair(1, "Every 1 minute"),
        Pair(3, "Every 3 minutes"),
        Pair(5, "Every 5 minutes"),
        Pair(10, "Every 10 minutes"),
        Pair(15, "Every 15 minutes"),
        Pair(30, "Every 30 minutes"),
        Pair(45, "Every 45 minutes"),
        Pair(60, "Every 1 hour"),
        Pair(180, "Every 3 hours"),
        Pair(360, "Every 6 hours"),
        Pair(1440, "Every 24 hours (Daily)")
    )

    // Current state of the active preview
    private var currentPhotoIndex = 0
    private var currentAlbumPaths = listOf<String>()
    private var currentAlbumName = "All Photos"
    private var isUserSelectingAlbum = false

    private val widgetUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val updatedId = intent?.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
            if (updatedId == appWidgetId) {
                syncPreviewFromWidget()
            }
        }
    }

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

        // Preview views
        previewCardContainer = findViewById(R.id.preview_card_container)
        ivWidgetPreview = findViewById(R.id.iv_widget_preview)
        previewEmptyContainer = findViewById(R.id.preview_empty_container)
        tvPreviewEmptyText = findViewById(R.id.tv_preview_empty_text)
        previewInfoOverlay = findViewById(R.id.preview_info_overlay)
        tvPreviewAlbumTitle = findViewById(R.id.tv_preview_album_title)
        tvPreviewBadge = findViewById(R.id.tv_preview_badge)
        tvPreviewCounter = findViewById(R.id.tv_preview_counter)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            previewCardContainer.clipToOutline = true
        }

        loadAlbums()
        setupIntervalSpinner()
        restoreCurrentConfiguration()
        setupAlbumSpinnerListener()

        btnClose.setOnClickListener {
            finish()
        }

        btnShuffleNow.setOnClickListener {
            shuffleCurrentPhoto()
        }

        // Tapping the preview card also triggers photo shuffle
        previewCardContainer.setOnClickListener {
            shuffleCurrentPhoto()
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

    override fun onResume() {
        super.onResume()
        syncPreviewFromWidget()
        val filter = IntentFilter(AlbumWidgetProvider.ACTION_WIDGET_UPDATED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(widgetUpdateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(widgetUpdateReceiver, filter)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(widgetUpdateReceiver)
        } catch (e: Exception) {
            // Ignore if not registered
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

    private fun setupAlbumSpinnerListener() {
        spinnerAlbum.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                if (!isUserSelectingAlbum) return
                if (position in albumOptions.indices) {
                    val selectedAlbumId = albumOptions[position].first
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val savedAlbumId = prefs.getString("flutter.album_widget_${appWidgetId}_album_id", null)

                    if (selectedAlbumId == savedAlbumId) {
                        val lastPath = prefs.getString("flutter.album_widget_${appWidgetId}_last_path", null)
                        val savedIndex = prefs.getLong("flutter.album_widget_${appWidgetId}_current_index", 0L).toInt()
                        updatePreviewForAlbum(selectedAlbumId, preferredPath = lastPath, preferredIndex = savedIndex)
                    } else {
                        updatePreviewForAlbum(selectedAlbumId, preferredIndex = 0)
                    }
                }
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
    }

    private fun restoreCurrentConfiguration() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isExisting = prefs.contains("flutter.album_widget_${appWidgetId}_album_id")
        val savedAlbumId = prefs.getString("flutter.album_widget_${appWidgetId}_album_id", null)
        val savedInterval = prefs.getLong("flutter.album_widget_${appWidgetId}_interval_minutes", 0L).toInt()
        val savedIsRandom = prefs.getBoolean("flutter.album_widget_${appWidgetId}_is_random", true)
        val savedIndex = prefs.getLong("flutter.album_widget_${appWidgetId}_current_index", 0L).toInt()
        val lastPath = prefs.getString("flutter.album_widget_${appWidgetId}_last_path", null)

        if (isExisting) {
            btnSave.text = "Save Settings"
            btnShuffleNow.visibility = View.VISIBLE

            var selectedIndex = 0
            if (savedAlbumId != null) {
                val albumIndex = albumOptions.indexOfFirst { it.first == savedAlbumId }
                if (albumIndex >= 0) {
                    selectedIndex = albumIndex
                }
            }
            spinnerAlbum.setSelection(selectedIndex)

            val intervalIndex = intervalOptions.indexOfFirst { it.first == savedInterval }
            if (intervalIndex >= 0) {
                spinnerInterval.setSelection(intervalIndex)
            } else {
                val defaultIndex = intervalOptions.indexOfFirst { it.first == 0 }.coerceAtLeast(0)
                spinnerInterval.setSelection(defaultIndex)
            }

            if (savedIsRandom) {
                radioRandom.isChecked = true
            } else {
                radioOrdered.isChecked = true
            }

            val targetAlbumId = savedAlbumId ?: albumOptions[selectedIndex].first
            updatePreviewForAlbum(targetAlbumId, preferredPath = lastPath, preferredIndex = savedIndex, animate = false)
        } else {
            btnSave.text = "Apply & Add Widget"
            btnShuffleNow.visibility = View.VISIBLE
            radioRandom.isChecked = true
            val defaultIndex = intervalOptions.indexOfFirst { it.first == 0 }.coerceAtLeast(0)
            spinnerInterval.setSelection(defaultIndex)

            val defaultAlbumId = albumOptions.firstOrNull()?.first ?: "all_photos"
            updatePreviewForAlbum(defaultAlbumId, preferredIndex = 0, animate = false)
        }

        // Allow subsequent user selections to trigger preview updates
        spinnerAlbum.post {
            isUserSelectingAlbum = true
        }
    }

    /**
     * Synchronizes preview with the actual home screen widget state if they share the same album.
     */
    private fun syncPreviewFromWidget() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedAlbumId = prefs.getString("flutter.album_widget_${appWidgetId}_album_id", null) ?: return
        val selectedAlbumId = albumOptions.getOrNull(spinnerAlbum.selectedItemPosition)?.first

        // Only sync if the user currently has the widget's configured album selected
        if (selectedAlbumId == savedAlbumId) {
            val lastPath = prefs.getString("flutter.album_widget_${appWidgetId}_last_path", null)
            val currentIndex = prefs.getLong("flutter.album_widget_${appWidgetId}_current_index", 0L).toInt()
            updatePreviewForAlbum(savedAlbumId, preferredPath = lastPath, preferredIndex = currentIndex, animate = true)
        }
    }

    /**
     * Updates preview for a given album ID, resolving file paths and picking an initial photo.
     */
    private fun updatePreviewForAlbum(
        albumId: String,
        preferredPath: String? = null,
        preferredIndex: Int? = null,
        animate: Boolean = true
    ) {
        val (resolvedName, paths) = AlbumWidgetProvider.getAlbumImagePaths(this, albumId)
        currentAlbumPaths = paths
        currentAlbumName = resolvedName

        if (paths.isEmpty()) {
            showEmptyPreview(resolvedName)
            return
        }

        val pathIndex = if (preferredPath != null && paths.contains(preferredPath)) {
            paths.indexOf(preferredPath)
        } else if (preferredIndex != null && preferredIndex in paths.indices) {
            preferredIndex
        } else {
            currentPhotoIndex.coerceIn(0, paths.size - 1)
        }

        currentPhotoIndex = pathIndex
        displayPreviewImage(paths[currentPhotoIndex], currentPhotoIndex, paths.size, currentAlbumName, animate)
    }

    /**
     * Displays a decoded bitmap in the preview container.
     */
    private fun displayPreviewImage(
        imagePath: String,
        index: Int,
        total: Int,
        albumName: String,
        animate: Boolean = true
    ) {
        val bitmap = WallpaperHelper.decodeWidgetBitmap(imagePath, 600, 600)
        if (bitmap != null) {
            ivWidgetPreview.visibility = View.VISIBLE
            previewEmptyContainer.visibility = View.GONE
            previewInfoOverlay.visibility = View.VISIBLE

            ivWidgetPreview.setImageBitmap(bitmap)
            if (animate) {
                ivWidgetPreview.alpha = 0.4f
                ivWidgetPreview.animate().alpha(1f).setDuration(220).start()
            } else {
                ivWidgetPreview.alpha = 1f
            }

            tvPreviewAlbumTitle.text = albumName
            tvPreviewBadge.text = "${index + 1}/$total"
            tvPreviewCounter.text = "Photo ${index + 1} of $total"
            btnShuffleNow.isEnabled = total > 1
        } else {
            showEmptyPreview(albumName)
        }
    }

    private fun showEmptyPreview(albumName: String) {
        ivWidgetPreview.visibility = View.GONE
        previewInfoOverlay.visibility = View.GONE
        previewEmptyContainer.visibility = View.VISIBLE

        tvPreviewEmptyText.text = "No photos in $albumName"
        tvPreviewCounter.text = "0 photos"
        btnShuffleNow.isEnabled = false
    }

    /**
     * Advances to the next photo in the current album and synchronizes with the home screen widget.
     */
    private fun shuffleCurrentPhoto() {
        if (currentAlbumPaths.isEmpty()) {
            Toast.makeText(this, "No photos in this album to shuffle", Toast.LENGTH_SHORT).show()
            return
        }
        if (currentAlbumPaths.size == 1) {
            Toast.makeText(this, "Only 1 photo in this album", Toast.LENGTH_SHORT).show()
            return
        }

        val isRandom = radioRandom.isChecked
        val newIndex = if (isRandom && currentAlbumPaths.size > 1) {
            var r = Random.nextInt(currentAlbumPaths.size)
            if (r == currentPhotoIndex) {
                r = (r + 1) % currentAlbumPaths.size
            }
            r
        } else {
            (currentPhotoIndex + 1) % currentAlbumPaths.size
        }

        currentPhotoIndex = newIndex
        val newPath = currentAlbumPaths[currentPhotoIndex]

        val selectedAlbumIndex = spinnerAlbum.selectedItemPosition.coerceIn(0, albumOptions.size - 1)
        val selectedAlbum = albumOptions[selectedAlbumIndex]
        val albumId = selectedAlbum.first
        val rawName = selectedAlbum.second.substringBeforeLast(" (")
        val albumName = if (albumId == "all_photos") "All Photos" else rawName

        // Update widget config in SharedPreferences so home screen widget and configure screen stay in lockstep
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("flutter.album_widget_${appWidgetId}_album_id", albumId)
            .putString("flutter.album_widget_${appWidgetId}_album_name", albumName)
            .putBoolean("flutter.album_widget_${appWidgetId}_is_random", isRandom)
            .putLong("flutter.album_widget_${appWidgetId}_current_index", currentPhotoIndex.toLong())
            .putString("flutter.album_widget_${appWidgetId}_last_path", newPath)
            .apply()

        // Update home screen widget immediately
        val appWidgetManager = AppWidgetManager.getInstance(this)
        AlbumWidgetProvider.updateWidget(this, appWidgetManager, appWidgetId)

        // Update preview image with smooth animation
        displayPreviewImage(newPath, currentPhotoIndex, currentAlbumPaths.size, currentAlbumName, animate = true)

        Toast.makeText(this, "Shuffled to photo ${currentPhotoIndex + 1} of ${currentAlbumPaths.size}", Toast.LENGTH_SHORT).show()
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
            .putLong("flutter.album_widget_${appWidgetId}_current_index", currentPhotoIndex.toLong())
            .apply()

        // Render widget immediately on home screen
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
