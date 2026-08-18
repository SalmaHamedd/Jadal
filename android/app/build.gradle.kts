plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google's docs require google-services to be applied last.
    id("com.google.gms.google-services")
}

android {
    namespace = "com.jadalplatform.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications: it uses java.time APIs that
        // don't exist below API 26, so they must be desugared. The plugin fails
        // to build without this even when scheduled notifications are unused.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Final, published application ID. It is baked into the Firebase
        // Android app registration and google-services.json — changing it
        // means re-registering the app in Firebase.
        applicationId = "com.jadalplatform.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backs isCoreLibraryDesugaringEnabled above; version pinned to the one
    // flutter_local_notifications 22.x is built against.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}