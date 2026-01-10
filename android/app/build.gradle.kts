plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smarttools.storageanalyzer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Unique Application ID for Smart Storage Analyzer
        applicationId = "com.smarttools.storageanalyzer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val keystore: String? = System.getenv("KEY_STORE")
        if (keystore != null) {
            create("release") {
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
                storeFile = file(keystore)
                storePassword = System.getenv("STORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Enable minification and resource shrinking for smaller APK size
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Use ProGuard files for code optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Use release signing configuration if available, otherwise use debug
            signingConfig = if (signingConfigs.names.contains("release")) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        debug {
            // Debug build configuration
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // WorkManager for scheduling periodic notifications
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    // Core AndroidX dependencies
    implementation("androidx.core:core-ktx:1.12.0")
    // DocumentFile for SAF operations
    implementation("androidx.documentfile:documentfile:1.0.1")
}
