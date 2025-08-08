# NeruLibrary ProGuard Rules for Release Build Optimization
# Add project specific ProGuard rules here.

## Flutter-specific optimizations
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Google Play Core (for app bundles and dynamic features)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Supabase and authentication
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keepclassmembers class * extends com.supabase.** { *; }

## Dio HTTP client
-keep class dio.** { *; }
-keep class com.dio.** { *; }
-keepclassmembers class * extends dio.** { *; }

## SQLite and database
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-keep class net.sqlcipher.** { *; }

## PDF and EPUB readers
-keep class com.github.barteksc.pdfviewer.** { *; }
-keep class nl.siegmann.epublib.** { *; }

## SharedPreferences and secure storage
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

## Path provider and file handling
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class androidx.core.content.** { *; }

## Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

## Image caching and network
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.baseflow.** { *; }

## Connectivity
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

## Riverpod state management (preserve generated code)
-keep class **$*Provider { *; }
-keep class **$*Notifier { *; }
-keep @riverpod.annotation.* class * { *; }
-keepclassmembers class * {
    @riverpod.annotation.* *;
}

## JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

## Model classes - keep all data models
-keep class com.nerufuyo.nerulibrary.features.**.models.** { *; }
-keep class com.nerufuyo.nerulibrary.features.**.entities.** { *; }
-keep class com.nerufuyo.nerulibrary.core.**.models.** { *; }

## API response models
-keepclassmembers class * {
    @com.fasterxml.jackson.annotation.* *;
}

## Reflection protection for critical classes
-keep class com.nerufuyo.nerulibrary.core.config.** { *; }
-keep class com.nerufuyo.nerulibrary.core.constants.** { *; }

## Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

## Optimization settings
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontskipnonpubliclibraryclassmembers
-dontpreverify
-verbose

## Code obfuscation
-repackageclasses 'o'
-allowaccessmodification
-flattenpackagehierarchy

## Remove unused code
-dontwarn org.xmlpull.v1.**
-dontwarn org.kxml2.io.**
-dontwarn android.content.res.**
-dontwarn org.slf4j.**

## Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Keep getters and setters for model classes
-keepclassmembers public class * {
    void set*(***);
    *** get*();
}

## Preserve annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

## Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

## Crashlytics (if added later)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

## Performance optimizations
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*,!code/allocation/variable
