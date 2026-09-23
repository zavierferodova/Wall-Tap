package com.zavierdev.walltap

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.util.DisplayMetrics
import android.view.WindowManager
import java.io.File
import kotlin.math.max
import kotlin.math.min

object WallpaperHelper {

    fun getDisplayDimensions(context: Context): Pair<Int, Int> {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = windowManager?.currentWindowMetrics
            val bounds = metrics?.bounds ?: Rect(0, 0, 1080, 2400)
            Pair(bounds.width(), bounds.height())
        } else {
            val displayMetrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager?.defaultDisplay?.getRealMetrics(displayMetrics)
            Pair(displayMetrics.widthPixels.coerceAtLeast(1080), displayMetrics.heightPixels.coerceAtLeast(1920))
        }
    }

    fun decodeSampledBitmapFromFile(
        path: String,
        reqWidth: Int,
        reqHeight: Int,
        config: Bitmap.Config = Bitmap.Config.ARGB_8888
    ): Bitmap? {
        val file = File(path)
        if (!file.exists() || !file.canRead()) return null

        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(path, options)

        var inSampleSize = 1
        val height = options.outHeight
        val width = options.outWidth

        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while ((halfHeight / inSampleSize) >= reqHeight || (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }

        val decodeOptions = BitmapFactory.Options().apply {
            this.inSampleSize = inSampleSize
            inPreferredConfig = config
        }
        return try {
            BitmapFactory.decodeFile(path, decodeOptions)
        } catch (e: OutOfMemoryError) {
            try {
                decodeOptions.inSampleSize = inSampleSize * 2
                BitmapFactory.decodeFile(path, decodeOptions)
            } catch (t: Throwable) {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Decodes and strictly scales an image for RemoteViews widgets.
     * Guarantees that the resulting bitmap fits comfortably within the Android Binder
     * transaction buffer limit (1MB) by capping dimensions to reqWidth/reqHeight and
     * using RGB_565 (with ARGB_8888 fallback).
     */
    fun decodeWidgetBitmap(
        path: String,
        reqWidth: Int,
        reqHeight: Int
    ): Bitmap? {
        val file = File(path)
        if (!file.exists() || !file.canRead()) return null

        return try {
            val boundsOptions = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, boundsOptions)

            val origWidth = boundsOptions.outWidth
            val origHeight = boundsOptions.outHeight
            if (origWidth <= 0 || origHeight <= 0) return null

            // Calculate inSampleSize such that both dimensions are comfortably downsampled
            var inSampleSize = 1
            while ((origWidth / inSampleSize) > reqWidth * 2 || (origHeight / inSampleSize) > reqHeight * 2) {
                inSampleSize *= 2
            }

            val decodeOptions = BitmapFactory.Options().apply {
                this.inSampleSize = inSampleSize
                inPreferredConfig = Bitmap.Config.RGB_565
            }

            var decoded: Bitmap? = try {
                BitmapFactory.decodeFile(path, decodeOptions)
            } catch (e: OutOfMemoryError) {
                decodeOptions.inSampleSize = inSampleSize * 2
                BitmapFactory.decodeFile(path, decodeOptions)
            }

            if (decoded == null) {
                // Fallback to ARGB_8888 if RGB_565 decoding is unsupported for this format
                decodeOptions.inPreferredConfig = Bitmap.Config.ARGB_8888
                decoded = BitmapFactory.decodeFile(path, decodeOptions)
            }

            if (decoded == null) return null

            // Strictly scale down so that neither dimension exceeds reqWidth / reqHeight
            val currentW = decoded.width
            val currentH = decoded.height
            val scale = min(reqWidth.toFloat() / currentW, reqHeight.toFloat() / currentH)

            if (scale < 1.0f) {
                val targetW = max(1, (currentW * scale).toInt())
                val targetH = max(1, (currentH * scale).toInt())
                val scaled = Bitmap.createScaledBitmap(decoded, targetW, targetH, true)
                if (scaled != decoded) {
                    decoded.recycle()
                }
                scaled
            } else {
                decoded
            }
        } catch (e: OutOfMemoryError) {
            null
        } catch (e: Exception) {
            null
        }
    }

    fun scaleBitmap(src: Bitmap, targetWidth: Int, targetHeight: Int, scaleType: String): Bitmap {
        return when (scaleType.lowercase()) {
            "crop", "center_crop", "centercrop" -> {
                val scale = max(targetWidth.toFloat() / src.width, targetHeight.toFloat() / src.height)
                val scaledWidth = (src.width * scale).toInt()
                val scaledHeight = (src.height * scale).toInt()
                val scaledBitmap = Bitmap.createScaledBitmap(src, scaledWidth, scaledHeight, true)
                val x = ((scaledWidth - targetWidth) / 2).coerceAtLeast(0)
                val y = ((scaledHeight - targetHeight) / 2).coerceAtLeast(0)
                val cropped = Bitmap.createBitmap(scaledBitmap, x, y, min(targetWidth, scaledWidth - x), min(targetHeight, scaledHeight - y))
                if (scaledBitmap != src && scaledBitmap != cropped) scaledBitmap.recycle()
                cropped
            }
            "fit" -> {
                val scale = min(targetWidth.toFloat() / src.width, targetHeight.toFloat() / src.height)
                val scaledWidth = (src.width * scale).toInt()
                val scaledHeight = (src.height * scale).toInt()
                val scaledBitmap = Bitmap.createScaledBitmap(src, scaledWidth, scaledHeight, true)

                val output = Bitmap.createBitmap(targetWidth, targetHeight, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(output)
                canvas.drawColor(Color.BLACK)
                val left = (targetWidth - scaledWidth) / 2f
                val top = (targetHeight - scaledHeight) / 2f
                canvas.drawBitmap(scaledBitmap, left, top, Paint(Paint.FILTER_BITMAP_FLAG))
                if (scaledBitmap != src) scaledBitmap.recycle()
                output
            }
            else -> { // "full", "full_image", "fullimage"
                Bitmap.createScaledBitmap(src, targetWidth, targetHeight, true)
            }
        }
    }

    fun setDeviceWallpaper(
        context: Context,
        imagePath: String,
        targetScreen: String = "both",
        scaleType: String = "full"
    ): Boolean {
        try {
            val (screenWidth, screenHeight) = getDisplayDimensions(context)
            val rawBitmap = decodeSampledBitmapFromFile(imagePath, screenWidth, screenHeight) ?: return false
            val scaledBitmap = scaleBitmap(rawBitmap, screenWidth, screenHeight, scaleType)

            val wallpaperManager = WallpaperManager.getInstance(context)
            val flags = when (targetScreen.lowercase()) {
                "home", "homescreen" -> WallpaperManager.FLAG_SYSTEM
                "lock", "lockscreen" -> WallpaperManager.FLAG_LOCK
                else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
            }

            wallpaperManager.setBitmap(scaledBitmap, null, true, flags)
            if (scaledBitmap != rawBitmap) {
                scaledBitmap.recycle()
            }
            rawBitmap.recycle()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}
