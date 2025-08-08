plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nerufuyo.nerulibrary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.nerufuyo.nerulibrary"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multiDex for large apps
        multiDexEnabled = true
        
        // Optimize for release builds
        ndk {
            debugSymbolLevel = "SYMBOL_TABLE"
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("NERULIBRARY_KEY_ALIAS") ?: "nerulibrary"
            keyPassword = System.getenv("NERULIBRARY_KEY_PASSWORD") ?: "nerulibrary123"
            storeFile = file(System.getenv("NERULIBRARY_KEYSTORE_PATH") ?: "nerulibrary-release-key.keystore")
            storePassword = System.getenv("NERULIBRARY_STORE_PASSWORD") ?: "nerulibrary123"
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            
            // Use release signing config when available, fallback to debug
            signingConfig = if (System.getenv("NERULIBRARY_KEYSTORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Optimize build performance
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
    
    // Bundle configuration for smaller APK sizes
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
    
    // Lint configuration
    lint {
        disable += setOf("InvalidPackage")
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}
