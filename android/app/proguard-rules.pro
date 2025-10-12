# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep all classes for Room database
-keep class com.justspent.app.data.model.** { *; }
-keep class com.justspent.app.data.dao.** { *; }
-keep class com.justspent.app.data.database.** { *; }

# Keep Hilt generated classes
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Keep Kotlinx DateTime
-keep class kotlinx.datetime.** { *; }

# Keep BigDecimal serialization
-keep class java.math.BigDecimal { *; }

# Compose specific rules
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# Retrofit and Gson (for future API integration)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Google Assistant App Actions
-keep class com.google.assistant.** { *; }
-dontwarn com.google.assistant.**