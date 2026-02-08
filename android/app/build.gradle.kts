plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.smarttools.storageanalyzer"
    compileSdk = 36
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
        // Explicitly set SDK versions for Google Play compliance
        minSdk = flutter.minSdkVersion  // Android 5.0 (Lollipop) - Google Play minimum
        targetSdk = 35  // Android 15 - Required by Google Play Console
        // compileSdk is set to 36 in the android block above (required by dependencies)
        versionCode = 6
        versionName = "1.0.5"
    }

    signingConfigs {
        // First try to load from local key.properties file
        val keystorePropertiesFile = rootProject.file("key.properties")
        
        if (keystorePropertiesFile.exists()) {
            // Local signing configuration
            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        } else {
            // Fallback to environment variables for CI/CD
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
