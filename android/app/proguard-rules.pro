# Keep ML Kit text recognition classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep Firebase ML dependencies if used
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Flutter generated plugin registrants
-keep class io.flutter.plugins.** { *; }

# Optional: keep your own classes (replace with your package)
-keep class com.wecare.** { *; }
