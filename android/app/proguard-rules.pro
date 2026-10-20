# Google Mobile Ads uses WorkManager, which builds its Room database by
# reflection. Without these rules R8 strips the generated database classes and
# the release build crashes on launch with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# shared_preferences (the intro-seen flag) calls into its Android side by
# method name from native code. R8 removed those methods, so reading the flag
# failed with NoSuchMethodError in release builds.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
# Its native bridge (jni) finds Kotlin coroutine classes such as Continuation
# and CoroutineSingletons by name, so R8 must not rename or drop them.
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
