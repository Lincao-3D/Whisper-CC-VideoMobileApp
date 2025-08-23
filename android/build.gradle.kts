plugins {
    id("com.android.application") version "8.1.1" apply false
    id("org.jetbrains.kotlin.android") version "1.8.10" apply false
    id("com.facebook.react") version "0.76.9" apply false
}

// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    val buildToolsVersion by extra("34.0.0")
    val minSdkVersion by extra(24)
    val compileSdkVersion by extra(34)
    val targetSdkVersion by extra(34)

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // This is the crucial line that tells Gradle where to find the plugin.
        classpath("com.android.tools.build:gradle:8.1.1")
        // This is where you would add other buildscript classpath dependencies.
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.10")
    }
}

// Optional but helpful to align all org.jetbrains.kotlin deps
subprojects {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("1.8.10")
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { setUrl("https://www.jitpack.io") }
        // Point to the local node_modules directory for React Native artifacts.
        // This is the correct and necessary line.
        maven { setUrl("$rootDir/../node_modules/react-native/android") }
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "org.jetbrains.kotlin") {
            useVersion("1.8.10")
        }
    }
}