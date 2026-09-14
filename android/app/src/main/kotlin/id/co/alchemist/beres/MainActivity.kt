package id.co.alchemist.beres

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri as AndroidUri
import android.view.WindowManager
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {

    private val batteryChannel = "id.co.alchemist.beres/battery"
    private val ringtoneChannel = "id.co.alchemist.beres/ringtone"
    private val secureScreenChannel = "id.co.alchemist.beres/secure_screen"
    private val textRecognitionChannel = "id.co.alchemist.beres/text_recognition"
    private val ringtonePickerRequestCode = 4271

    private var pendingRingtoneResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            batteryChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "requestIgnoreBatteryOptimizations") {
                requestIgnoreBatteryOptimizations()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ringtoneChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "pickRingtone") {
                pendingRingtoneResult = result
                launchRingtonePicker()
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureScreenChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            textRecognitionChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "recognize") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("NO_PATH", "path is required", null)
                } else {
                    recognizeText(path, result)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun recognizeText(path: String, result: MethodChannel.Result) {
        try {
            val image = InputImage.fromFilePath(this, AndroidUri.fromFile(File(path)))
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val lines = mutableListOf<Map<String, Any>>()
                    for (block in visionText.textBlocks) {
                        for (line in block.lines) {
                            val box = line.boundingBox
                            lines.add(
                                mapOf(
                                    "text" to line.text,
                                    "top" to (box?.top ?: 0).toDouble(),
                                    "bottom" to (box?.bottom ?: 0).toDouble(),
                                    "left" to (box?.left ?: 0).toDouble(),
                                ),
                            )
                        }
                    }
                    recognizer.close()
                    result.success(lines)
                }
                .addOnFailureListener { error ->
                    recognizer.close()
                    result.error("RECOGNITION_FAILED", error.message, null)
                }
        } catch (e: Exception) {
            result.error("RECOGNITION_FAILED", e.message, null)
        }
    }

    private fun launchRingtonePicker() {
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            )
        }
        startActivityForResult(intent, ringtonePickerRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != ringtonePickerRequestCode) return

        val result = pendingRingtoneResult
        pendingRingtoneResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri: Uri? = data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null) {
            result.success(mapOf("relativePath" to null, "name" to null))
            return
        }

        try {
            val ringtone = RingtoneManager.getRingtone(this, uri)
            val name = ringtone?.getTitle(this) ?: "Custom"

            val ringtonesDir = File(filesDir.parent, "app_flutter/ringtones")
            if (!ringtonesDir.exists()) ringtonesDir.mkdirs()
            val destFile = File(ringtonesDir, "alarm_${System.currentTimeMillis()}.sound")

            contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output -> input.copyTo(output) }
            }

            result.success(
                mapOf(
                    "relativePath" to "ringtones/${destFile.name}",
                    "name" to name,
                ),
            )
        } catch (e: Exception) {
            result.error("RINGTONE_COPY_FAILED", e.message, null)
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                ).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        }
    }
}
