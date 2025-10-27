#!/bin/bash

# Script para obtener el SHA-256 fingerprint del certificado de la app Android

echo "🔍 Obteniendo SHA-256 fingerprint del certificado..."

# Método 1: Desde el keystore de debug
KEYSTORE="$HOME/.android/debug.keystore"
if [ -f "$KEYSTORE" ]; then
    echo "✅ Keystore encontrado: $KEYSTORE"
    echo "📝 Ejecutando: keytool -list -v -keystore $KEYSTORE -alias androiddebugkey -storepass android -keypass android"
    keytool -list -v -keystore "$KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>&1 | grep -E "SHA256|SHA-256" || echo "⚠️  No se pudo extraer SHA-256 del keystore"
else
    echo "❌ Keystore no encontrado en: $KEYSTORE"
fi

echo ""
echo "---"

# Método 2: Desde el APK actual
APK="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK" ]; then
    echo "✅ APK encontrado: $APK"
    echo "📝 Extrayendo certificado del APK..."
    unzip -p "$APK" META-INF/*.RSA > /tmp/cert.pem 2>/dev/null
    
    if [ -s /tmp/cert.pem ]; then
        openssl pkcs7 -in /tmp/cert.pem -inform DER -print_certs 2>/dev/null | openssl x509 -noout -fingerprint -sha256 2>/dev/null || {
            # Alternativa: usar keytool
            keytool -printcert -file /tmp/cert.pem 2>&1 | grep -E "SHA256|SHA-256" || echo "⚠️  No se pudo extraer SHA-256 del APK"
        }
    else
        echo "⚠️  No se pudo extraer el certificado del APK"
    fi
    
    rm -f /tmp/cert.pem
else
    echo "❌ APK no encontrado: $APK"
fi

echo ""
echo "---"
echo "💡 Para obtener el SHA-256 manualmente:"
echo "   1. Abre Android Studio"
echo "   2. Build > Generate Signed Bundle / APK"
echo "   3. O usa: keytool -list -v -keystore <keystore> -alias <alias>"
echo ""
echo "💡 Para producción, ejecuta:"
echo "   keytool -list -v -keystore android/app/key.jks -alias <tu-alias>"
echo ""
