##########################
## React Native Core
##########################
# Keep React Native bridge & core classes
-keep class com.facebook.react.** { *; }
-dontwarn com.facebook.react.**

# Keep Hermes engine
-keep class com.facebook.hermes.** { *; }
-dontwarn com.facebook.hermes.**

##########################
## FFmpegKit
##########################
-keep class com.arthenica.** { *; }
-dontwarn com.arthenica.**

##########################
## TensorFlow Lite
##########################
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

##########################
## ONNX Runtime
##########################
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

##########################
## Whisper / TFLite / ML Bindings
##########################
# Keep your Whisper wrapper package — adjust to your namespace
-keep class com.whisper.** { *; }
# Keep any generated model binding classes
-keep class your.package.models.** { *; }

##########################
## JNI / Native Methods
##########################
# Keep native method signatures for JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

##########################
## Annotations
##########################
-dontwarn javax.annotation.**

##########################
## Optional: JSON / Reflection-based Mappers
##########################
# If you use libraries like Gson, Moshi, Jackson — keep model classes
# Example for Gson:
# -keep class your.package.network.models.** { *; }
