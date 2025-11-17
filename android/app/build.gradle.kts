import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.devtools.ksp")
    id("dagger.hilt.android.plugin")
    id("kotlin-parcelize")
    jacoco
}

// Load keystore properties from keystore.properties file
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.justspent.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.justspent.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 2
        versionName = "1.0.0-beta.1"

        testInstrumentationRunner = "com.justspent.app.HiltTestRunner"
        // Temporarily disable clearPackageData to fix test discovery issue
        // testInstrumentationRunnerArguments["clearPackageData"] = "true"

        vectorDrawables {
            useSupportLibrary = true
        }

        // Enable multidex for tests
        multiDexEnabled = true
    }

    testOptions {
        // NOTE: After AGP 8.7.3 upgrade, tests run successfully without orchestrator
        // TestOrchestrator disabled - not needed with AGP 8.7.3
        // Tests run directly via Gradle without orchestrator overhead
        // execution = "ANDROIDX_TEST_ORCHESTRATOR"
        animationsDisabled = true

        // Configure Robolectric for unit tests
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
        }
    }

    // Signing configurations for release builds
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("RELEASE_STORE_FILE") ?: "")
                storePassword = keystoreProperties.getProperty("RELEASE_STORE_PASSWORD")
                keyAlias = keystoreProperties.getProperty("RELEASE_KEY_ALIAS")
                keyPassword = keystoreProperties.getProperty("RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Use release signing configuration if keystore properties exist
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        viewBinding = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.15"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
    buildToolsVersion = "34.0.0"

    // Configure source sets to use shared folder for assets
    // This allows direct reference to shared/ files without copying
    sourceSets {
        getByName("main") {
            assets.srcDirs(
                "src/main/assets",
                "${project.rootDir}/../shared"  // Reference shared folder directly
            )
        }
    }
}

// Jacoco configuration for code coverage
tasks.register<JacocoReport>("jacocoTestReport") {
    dependsOn("testDebugUnitTest")

    reports {
        xml.required.set(true)
        html.required.set(true)
    }

    val fileFilter = listOf(
        "**/R.class",
        "**/R$*.class",
        "**/BuildConfig.*",
        "**/Manifest*.*",
        "**/*Test*.*",
        "android/**/*.*",
        "**/data/models/**",
        "**/di/**"
    )

    val debugTree = fileTree("${project.buildDir}/tmp/kotlin-classes/debug") {
        exclude(fileFilter)
    }

    val mainSrc = "${project.projectDir}/src/main/java"

    sourceDirectories.setFrom(files(mainSrc))
    classDirectories.setFrom(files(debugTree))
    executionData.setFrom(fileTree(project.buildDir) {
        include("jacoco/testDebugUnitTest.exec")
    })
}

dependencies {
    // Core Android
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // Compose BOM
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    
    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.5")
    
    // ViewModel & LiveData
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-process:2.7.0")
    
    // Room Database
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")
    
    // Hilt Dependency Injection
    implementation("com.google.dagger:hilt-android:2.50")
    ksp("com.google.dagger:hilt-compiler:2.50")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    
    // Google Assistant & App Actions - commented out for now to fix build
    // implementation("com.google.assistant:app-actions:1.0.0")

    // Speech Recognition
    implementation("androidx.core:core-ktx:1.12.0")

    // Accompanist Permissions
    implementation("com.google.accompanist:accompanist-permissions:0.32.0")

    // Date & Time
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")
    
    // JSON Serialization (kotlinx-serialization for Currency loading)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.7.0")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.2.1")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("androidx.room:room-testing:2.6.1")
    testImplementation("androidx.arch.core:core-testing:2.2.0")
    testImplementation("com.google.truth:truth:1.1.4")
    testImplementation("org.robolectric:robolectric:4.11.1")
    testImplementation("androidx.test:core:1.5.0")  // For ApplicationProvider in Robolectric tests
    
    // Multidex
    implementation("androidx.multidex:multidex:2.0.1")

    // Android Test
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.test:rules:1.5.0")  // For GrantPermissionRule
    androidTestImplementation(platform("androidx.compose:compose-bom:2023.10.01"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("androidx.navigation:navigation-testing:2.7.5")
    androidTestImplementation("androidx.room:room-testing:2.6.1")
    androidTestImplementation("com.google.dagger:hilt-android-testing:2.50")
    kspAndroidTest("com.google.dagger:hilt-android-compiler:2.50")
    // Required for TestOrchestrator to run tests in isolation
    androidTestUtil("androidx.test:orchestrator:1.4.2")
    
    // Debug
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}