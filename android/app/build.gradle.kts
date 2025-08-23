plugins {
    id("com.android.application")
    id("com.facebook.react")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // AndroidX core dependencies
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.core:core-ktx:1.13.1")

    // React Native dependencies with BOM for version alignment
    implementation(platform("com.facebook.react:react-android-bom:0.71.8"))
    implementation("com.facebook.react:react-android")

    // Choose your JS engine:
    implementation("com.facebook.react:hermes-android")
    // Or, if you prefer JSC:
    // implementation("org.webkit:android-jsc:+")
}
