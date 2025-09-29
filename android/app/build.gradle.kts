plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // Google Services plugin
    id("dev.flutter.flutter-gradle-plugin") // must be after Android & Kotlin
}

android {
    namespace = "com.carlo.ascendia"        // MUST match Firebase package
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"                     // Fixes “Unknown Kotlin JVM target: 21”
    }

    defaultConfig {
        applicationId = "com.carlo.ascendia" // MUST match Firebase Android app
        minSdk = 23                          // Firebase requires 23+
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: replace with real signing for release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
