# R8 + ML Kit text recognition.
#
# The plugin google_mlkit_text_recognition references the language-specific
# recognizer-options classes in its initialize() switch, but only the Latin
# recognizer is bundled by default (per the package docs). The other scripts
# (Chinese, Devanagari, Japanese, Korean) require separate
# `com.google.mlkit:text-recognition-<script>` Gradle dependencies which we
# do NOT add — Brazilian delivery riders deal with Latin script addresses.
#
# Without these `-dontwarn` directives R8's minifyRelease step fails with
# "Missing class com.google.mlkit.vision.text.<script>.<...>" errors, even
# though the unused branches are unreachable at runtime. The `-keep` rule
# preserves the Latin recognizer's class names so ML Kit's reflection-based
# dispatch keeps working in the released APK.
#
# Sources:
# - google_mlkit_text_recognition pub.dev (Context7 2026-05-19 query)
# - ML Kit Android docs: https://developers.google.com/ml-kit/known-issues
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
