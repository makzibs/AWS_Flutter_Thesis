# flutter_secure_storage - Keep Tink crypto library
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }

# Google API client (required by Tink)
-keep class com.google.api.client.** { *; }
-dontwarn com.google.api.client.**

# Joda Time (required by Tink)
-keep class org.joda.time.** { *; }
-dontwarn org.joda.time.**

# Suppress warnings for optional dependencies
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**