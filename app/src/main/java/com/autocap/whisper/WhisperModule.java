import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.ReturnCode;
import java.io.File;

public class WhisperModule extends ReactContextBaseJavaModule {
    private static final String NAME = "WhisperModule";

    // Declare JNI methods
    private native void nativeInit(android.content.res.AssetManager assetManager, String packageName);
    private native String nativeTranscribe(String audioPath);

    public WhisperModule(ReactApplicationContext reactContext) {
        super(reactContext);
        nativeInit(reactContext.getAssets(), BuildConfig.APPLICATION_ID);
    }

    @Override
    public String getName() {
        return NAME;
    }

    @ReactMethod
    public void transcribe(String audioPath, Promise promise) {
        try {
            // Create temp WAV file in cache dir
            File cacheDir = getReactApplicationContext().getCacheDir();
            File wavFile = new File(cacheDir, "converted_input.wav");
            String wavPath = wavFile.getAbsolutePath();

            // FFmpeg command: convert to 16kHz mono WAV PCM16
            String cmd = String.format("-y -i %s -ar 16000 -ac 1 -c:a pcm_s16le %s",
                                       audioPath, wavPath);

            var session = FFmpegKit.execute(cmd);

            if (!ReturnCode.isSuccess(session.getReturnCode())) {
                promise.reject("FFMPEG_ERROR", "Audio conversion failed");
                return;
            }

            // Call JNI with converted WAV
            String text = nativeTranscribe(wavPath);
            promise.resolve(text);

            // Optional: delete temp file
            // wavFile.delete();

        } catch (Exception e) {
            promise.reject("TRANSCRIBE_ERROR", e);
        }
    }
}
