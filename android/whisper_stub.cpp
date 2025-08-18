#include <jni.h>
#include <android/log.h>

extern "C"
JNIEXPORT void JNICALL
Java_com_autocap_whisper_WhisperModule_nativeInit(JNIEnv* env, jobject thiz) {
    __android_log_print(
        ANDROID_LOG_WARN,
        "WhisperStub",
        "Stub Whisper JNI loaded. No actual transcription functionality."
    );
}
