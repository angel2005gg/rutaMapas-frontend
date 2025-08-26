plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Agrega esta línea
}

android {
    namespace = "com.example.ruta_map_frontend"
    compileSdk = flutter.compileSdkVersion
    // ✅ Forzar NDK recomendado por los plugins
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ✅ Habilitar desugaring para librerías core (java.time, etc.)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ruta_map_frontend"
        minSdk = 21  // Cambiar de 19 a 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ Dependencia para core library desugaring
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
