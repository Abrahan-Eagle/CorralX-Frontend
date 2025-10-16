# Optimizaciones gráficas para reducir errores de gralloc4
-keep class android.graphics.** { *; }
-keep class android.hardware.** { *; }
-dontwarn android.hardware.display.**

# Mantener las clases necesarias para ML Kit Text Recognition
-keep class com.google.mlkit.** { *; }
-keepnames class com.google.mlkit.**
-keepclassmembers class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Flutter y plugins esenciales
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# HTTP y networking
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# Camera y image picker
-keep class androidx.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn androidx.camera.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# QR Scanner
-keep class net.touchcapture.qr.flutterqr.** { *; }
-dontwarn net.touchcapture.qr.flutterqr.**

# WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn io.flutter.plugins.webviewflutter.**

# File picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Mobile scanner
-keep class net.sourceforge.zbar.** { *; }
-keep class com.journeyapps.barcodescanner.** { *; }
-dontwarn net.sourceforge.zbar.**
-dontwarn com.journeyapps.barcodescanner.**

# Printing
-keep class net.nfet.printing.** { *; }
-dontwarn net.nfet.printing.**

# PDF viewer
-keep class com.shockwave.** { *; }
-dontwarn com.shockwave.**

# Variables de entorno y dotenv
-keep class com.example.zonix.MainActivity { *; }
-keepclassmembers class com.example.zonix.MainActivity {
    *;
}

# Mantener nombres de clases para reflexión
-keepnames class * implements androidx.fragment.app.Fragment
-keepnames class * extends androidx.fragment.app.Fragment

# Evitar ofuscación de clases que usan reflexión
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Mantener clases de modelos de datos
-keep class com.example.zonix.** { *; }

# Reglas faltantes detectadas por R8
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn javax.xml.stream.XMLStreamException