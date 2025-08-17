package com.autocap.whisper;

import com.facebook.react.bridge.*;
import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = WhisperModule.NAME)
public class WhisperModule extends ReactContextBaseJavaModule {
    public static final String NAME = "Whisper";

    static {
        System.loadLibrary("whisper");
    }

    public WhisperModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return NAME;
    }

    @ReactMethod
    public void transcribe(String audioPath, Promise promise) {
        // TODO: call native C++ transcribe()
        promise.resolve("dummy transcript"); 
    }
}
