package id.polinema.campus_notify

import android.media.AudioManager
import android.media.RingtoneManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val soundChannel = "id.polinema.campus_notify/sound"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, soundChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "playNotificationSound") {
                    playNotificationSound()
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun playNotificationSound() {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            if (ringtone != null) {
                ringtone.play()
                return
            }
        } catch (_: Throwable) {
            // Fallback ke ToneGenerator di bawah jika ringtone default gagal.
        }

        try {
            val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
            toneGen.startTone(ToneGenerator.TONE_PROP_BEEP2, 350)
        } catch (_: Throwable) {
            // Abaikan bila perangkat tidak memiliki output audio.
        }
    }
}
