# Flutter reflectively references these; R8 cannot see the links.
-dontwarn io.flutter.embedding.**
-keep class io.flutter.** { *; }

# flutter_local_notifications serialises its scheduled-notification models
# with Gson. R8 renaming the fields makes the reschedule-after-reboot path
# fail silently, so the pending reminders never come back.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Gson needs the generic signatures and annotations of anything it maps.
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# The alarm plugin's receiver and foreground service are started by the
# system from the merged manifest, and its Pigeon models cross the platform
# channel by name.
-keep class com.gdelataillade.alarm.** { *; }
-dontwarn com.gdelataillade.alarm.**
