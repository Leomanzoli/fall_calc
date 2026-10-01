package com.fallcalc35

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Habilita exibição de ponta a ponta (edge-to-edge)
        // Compatível com Android 15 (SDK 35) e versões anteriores
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
