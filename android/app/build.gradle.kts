import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.descuentos_uy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    val keystoreProperties = Properties()
    // La ruta correcta para leer el key.properties desde aquí es ../key.properties
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            val store = keystoreProperties["storeFile"]?.toString()
            val storePass = keystoreProperties["storePassword"]?.toString()
            val alias = keystoreProperties["keyAlias"]?.toString()
            val keyPass = keystoreProperties["keyPassword"]?.toString()

            // --- LOGS DE DEPURACIÓN ---
            println("\n--- INICIO DEBUG FIRMA ---")
            println(">> Buscando key.properties en: ${keystorePropertiesFile.absolutePath}")
            println(">> ¿Archivo key.properties encontrado?: ${keystorePropertiesFile.exists()}")
            println(">> storeFile (leído desde el archivo): $store")
            println(">> storePassword (leído desde el archivo): ${if (storePass != null && storePass.isNotEmpty()) "Leído ✅" else "NO LEÍDO o VACÍO ❌"} ")
            println(">> keyAlias (leído desde el archivo): $alias")
            println(">> keyPassword (leído desde el archivo): ${if (keyPass != null && keyPass.isNotEmpty()) "Leído ✅" else "NO LEÍDO o VACÍO ❌"}")
            println("--- FIN DEBUG FIRMA ---\n")
            // --- FIN LOGS ---

            if (store != null) {
                storeFile = rootProject.file(store)
            }
            if (storePass != null) {
                storePassword = storePass
            }
            if (alias != null) {
                keyAlias = alias
            }
            if (keyPass != null) {
                keyPassword = keyPass
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.descuentos_uy"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // Esto asegura que el build 'release' USA la firma 'release'
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
