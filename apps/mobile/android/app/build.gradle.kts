import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
if (releaseSigningPropertiesFile.isFile) {
    releaseSigningPropertiesFile.inputStream().use(releaseSigningProperties::load)
}

val requiredReleaseSigningProperties =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingReleaseSigningProperties =
    requiredReleaseSigningProperties.filter {
        releaseSigningProperties.getProperty(it).isNullOrBlank()
    }
val releaseStoreFileValue =
    releaseSigningProperties.getProperty("storeFile")?.trim().orEmpty()
val releaseStoreFile =
    releaseStoreFileValue.takeIf(String::isNotEmpty)?.let(rootProject::file)
val releaseSigningConfigured =
    missingReleaseSigningProperties.isEmpty() && releaseStoreFile?.isFile == true
val releaseTaskRequested =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
val allowUnsignedRelease =
    providers.gradleProperty("MEDICAL_BOX_ALLOW_UNSIGNED_RELEASE")
        .map { it.equals("true", ignoreCase = true) }
        .orElse(false)
        .get()

if (releaseTaskRequested && !allowUnsignedRelease && !releaseSigningConfigured) {
    val reasons = buildList {
        if (missingReleaseSigningProperties.isNotEmpty()) {
            add("missing properties: ${missingReleaseSigningProperties.joinToString()}")
        }
        if (releaseStoreFileValue.isNotEmpty() && releaseStoreFile?.isFile != true) {
            add("storeFile does not exist: $releaseStoreFileValue")
        }
        if (!releaseSigningPropertiesFile.isFile) {
            add("android/key.properties does not exist")
        }
    }
    throw GradleException(
        "Release signing is not configured (${reasons.joinToString("; ")}). " +
            "Use android/key.properties for distribution builds. " +
            "MEDICAL_BOX_ALLOW_UNSIGNED_RELEASE=true is restricted to compile-only CI.",
    )
}

android {
    namespace = "com.medicalbox.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.medicalbox.app"
        minSdk = flutter.minSdkVersion
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] =
            providers.gradleProperty("KAKAO_NATIVE_APP_KEY")
                .orElse(providers.environmentVariable("KAKAO_NATIVE_APP_KEY"))
                .orElse("unconfigured")
                .get()
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseSigningProperties.getProperty("storePassword")
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
