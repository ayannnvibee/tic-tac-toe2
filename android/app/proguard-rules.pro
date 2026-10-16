# Google Mobile Ads uses WorkManager, which builds its Room database by
# reflection. Without these rules R8 strips the generated database classes and
# the release build crashes on launch with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
