package com.corralx.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Habilitar edge-to-edge display usando API moderna (WindowCompat)
        // Esta es la forma recomendada para Android 15+ y reemplaza las APIs obsoletas
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}

