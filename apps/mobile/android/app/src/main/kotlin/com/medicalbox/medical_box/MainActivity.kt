package com.medicalbox.app

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val textRecognizer by lazy {
        TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "medical_box/medicine_ocr",
        ).setMethodCallHandler { call, result ->
            if (call.method != "recognizeMedicineText") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("OCR_INVALID_IMAGE", "Image path is missing.", null)
                return@setMethodCallHandler
            }

            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            } catch (error: Exception) {
                result.error("OCR_INVALID_IMAGE", error.localizedMessage, null)
                return@setMethodCallHandler
            }
            textRecognizer
                .process(image)
                .addOnSuccessListener { recognized ->
                    val lines = recognized.textBlocks.flatMap { block ->
                        block.lines.map { line -> mapOf("text" to line.text) }
                    }
                    result.success(lines)
                }
                .addOnFailureListener { error ->
                    result.error("OCR_FAILED", error.localizedMessage, null)
                }
        }
    }

    override fun onDestroy() {
        textRecognizer.close()
        super.onDestroy()
    }
}
