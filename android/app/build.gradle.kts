plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.coin_nest"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.coin_nest"
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

        applicationVariants.all {
        val appVariant = this
        val buildTypeName = appVariant.buildType.name // "release" hoặc "debug"
        val version = appVariant.versionName // lấy từ pubspec.yaml (thông qua flutter.versionName)
        
        appVariant.outputs.all {
            val apkOutput = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            // Lấy tên kiến trúc chip (arm64-v8a, armeabi-v7a, x86_64)
            val abiName = apkOutput.getFilter(com.android.build.OutputFile.ABI) ?: "universal"
            
            // Định dạng: CoinNest_v1.0.0_release_arm64-v8a.apk
            apkOutput.outputFileName = "CoinNest_v${version}_${buildTypeName}_${abiName}.apk"
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-analytics")
}
