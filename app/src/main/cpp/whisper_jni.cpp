#include <jni.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>
#include <sys/stat.h>
#include <string>
#include <fstream>
#include "whisper.h"   // Ensure this is in your include path

#define LOG_TAG "WhisperJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Keep Whisper context as global so both init & transcribe can access
static struct whisper_context *ctx = nullptr;

extern "C" JNIEXPORT void JNICALL
Java_com_autocap_whisper_WhisperModule_nativeInit(
    JNIEnv *env,
    jobject thiz,
    jobject assetManager,
    jstring packageName
) {
    AAssetManager *mgr = AAssetManager_fromJava(env, assetManager);
    if (!mgr) {
        LOGE("AssetManager is null");
        return;
    }

    const char *assetPath = "models/ggml-small.bin";
    AAsset *asset = AAssetManager_open(mgr, assetPath, AASSET_MODE_STREAMING);
    if (!asset) {
        LOGE("Failed to open asset: %s", assetPath);
        return;
    }

    // Build /data/data/<package>/files path dynamically
    const char *pkg = env->GetStringUTFChars(packageName, nullptr);
    std::string dstPath = "/data/data/";
    dstPath += pkg;
    dstPath += "/files/ggml-small.bin";
    env->ReleaseStringUTFChars(packageName, pkg);

    // Copy model if it doesn't exist yet
    struct stat st;
    if (stat(dstPath.c_str(), &st) != 0) {
        LOGI("Copying Whisper model to %s", dstPath.c_str());
        FILE *out = fopen(dstPath.c_str(), "wb");
        if (!out) {
            LOGE("Failed to create file at %s", dstPath.c_str());
            AAsset_close(asset);
            return;
        }
        const size_t bufSize = 4096;
        char buf[bufSize];
        int readBytes;
        while ((readBytes = AAsset_read(asset, buf, bufSize)) > 0) {
            fwrite(buf, 1, readBytes, out);
        }
        fclose(out);
    }
    AAsset_close(asset);

    LOGI("Loading Whisper model from %s", dstPath.c_str());
    ctx = whisper_init_from_file(dstPath.c_str());
    if (!ctx) {
        LOGE("Failed to initialize Whisper context");
    }
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_autocap_whisper_WhisperModule_nativeTranscribe(
    JNIEnv *env,
    jobject thiz,
    jstring audioPath
) {
    const char *path = env->GetStringUTFChars(audioPath, nullptr);

    if (!ctx) {
        LOGE("Whisper context is null — call nativeInit first");
        env->ReleaseStringUTFChars(audioPath, path);
        return env->NewStringUTF("[Error: Whisper not initialized]");
    }

    // Configure parameters
    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.print_progress = false;
    params.print_special = false;
    params.print_realtime = false;
    params.translate = false;  // Keep original language
    params.language = nullptr; // Auto-detect

    // NOTE: This assumes 'path' points to a 16 kHz mono WAV file
    if (whisper_full(ctx, params, path, 0) != 0) {
        LOGE("Failed to run whisper_full on %s", path);
        env->ReleaseStringUTFChars(audioPath, path);
        return env->NewStringUTF("[Error: Failed to run transcription]");
    }

    // Build result string
    std::string transcript;
    int n_segments = whisper_full_n_segments(ctx);
    for (int i = 0; i < n_segments; ++i) {
        transcript += whisper_full_get_segment_text(ctx, i);
        transcript += " ";
    }

    env->ReleaseStringUTFChars(audioPath, path);
    return env->NewStringUTF(transcript.c_str());
}
