import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingFile = rootProject.file("key.properties").takeIf { it.exists() }
    ?: rootProject.file("../.tools/signing/android-key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signingProperties.load(it) }

val dartDefines = providers.gradleProperty("dart-defines").orNull
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?: emptyList()
val notificationTest = dartDefines.contains("UNITABLE_NOTIFICATION_TEST=true")
val localBuild = dartDefines.contains("UNITABLE_LOCAL_BUILD=true")

android {
    namespace = "net.neomenia.unitable"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "net.neomenia.unitable"
        if (notificationTest) applicationIdSuffix = ".debug"
        manifestPlaceholders["appLabel"] =
            if (notificationTest) "@string/app_name_notification_test" else "@string/app_name"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // gradle.properties disables Flutter's ABI offset so every APK uses pubspec.yaml's build number.
        versionCode = flutter.versionCode
        versionName = if (localBuild) "test+${flutter.versionName}" else flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (signingFile.exists()) {
                storeFile = file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

tasks.matching { it.name.startsWith("assemble") && it.name.endsWith("Release") || it.name.startsWith("bundle") && it.name.endsWith("Release") }.configureEach {
    doFirst {
        check(signingFile.exists()) { "Release signing key is missing. Run scripts/build-release.ps1 -Target android, or create android/key.properties." }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.documentfile:documentfile:1.0.1")
}
