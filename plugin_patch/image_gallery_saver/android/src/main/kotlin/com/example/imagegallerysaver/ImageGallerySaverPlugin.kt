package com.example.imagegallerysaver

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream

class ImageGallerySaverPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_gallery_saver")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "saveImageToGallery" -> {
                val image = call.argument<ByteArray>("imageBytes")
                val quality = call.argument<Int>("quality") ?: 80
                val name = call.argument<String>("name")

                result.success(saveImageToGallery(image!!, quality, name))
            }
            "saveFileToGallery" -> {
                val path = call.argument<String>("file")
                val name = call.argument<String>("name")

                result.success(saveFileToGallery(path!!, name))
            }
            else -> result.notImplemented()
        }
    }

    private fun saveImageToGallery(imageBytes: ByteArray, quality: Int, name: String?): Map<String, Any> {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        return saveBitmap(bitmap, quality, name)
    }

    private fun saveFileToGallery(filePath: String, name: String?): Map<String, Any> {
        return try {
            val fileName = name ?: filePath.substring(filePath.lastIndexOf("/") + 1)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                }
                
                val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                        val inputStream = File(filePath).inputStream()
                        inputStream.copyTo(outputStream)
                        inputStream.close()
                    }
                    
                    mapOf("isSuccess" to true, "filePath" to uri.toString())
                } else {
                    mapOf("isSuccess" to false, "errorMessage" to "Failed to create new MediaStore record")
                }
            } else {
                val galleryPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).toString()
                val file = File(galleryPath, fileName)
                
                File(filePath).inputStream().use { input ->
                    FileOutputStream(file).use { output ->
                        input.copyTo(output)
                    }
                }
                
                // Notify gallery about new image
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                val contentUri = Uri.fromFile(file)
                mediaScanIntent.data = contentUri
                context.sendBroadcast(mediaScanIntent)
                
                mapOf("isSuccess" to true, "filePath" to file.absolutePath)
            }
        } catch (e: IOException) {
            mapOf("isSuccess" to false, "errorMessage" to e.localizedMessage)
        }
    }

    private fun saveBitmap(bitmap: Bitmap, quality: Int, name: String?): Map<String, Any> {
        return try {
            val fileName = name ?: System.currentTimeMillis().toString() + ".jpg"
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                }
                
                val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                    }
                    
                    mapOf("isSuccess" to true, "filePath" to uri.toString())
                } else {
                    mapOf("isSuccess" to false, "errorMessage" to "Failed to create new MediaStore record")
                }
            } else {
                val galleryPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).toString()
                val file = File(galleryPath, fileName)
                
                FileOutputStream(file).use { outputStream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                }
                
                // Notify gallery about new image
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                val contentUri = Uri.fromFile(file)
                mediaScanIntent.data = contentUri
                context.sendBroadcast(mediaScanIntent)
                
                mapOf("isSuccess" to true, "filePath" to file.absolutePath)
            }
        } catch (e: IOException) {
            mapOf("isSuccess" to false, "errorMessage" to e.localizedMessage)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}