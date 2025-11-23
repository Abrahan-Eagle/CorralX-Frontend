#!/bin/bash

echo "🔍 Verificando Credenciales y Conectividad - CorralX"
echo "=================================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar Frontend .env
echo "1️⃣ VERIFICANDO FRONTEND (.env)"
echo "------------------------------"

if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env existe${NC}"
    
    # Verificar variables críticas
    echo ""
    echo "Variables críticas:"
    
    if grep -q "PUSHER_APP_KEY" .env; then
        PUSHER_KEY=$(grep "PUSHER_APP_KEY" .env | cut -d'=' -f2)
        echo -e "${GREEN}✅ PUSHER_APP_KEY: ${PUSHER_KEY:0:10}...${NC}"
    else
        echo -e "${RED}❌ PUSHER_APP_KEY no encontrada${NC}"
    fi
    
    if grep -q "PUSHER_APP_CLUSTER" .env; then
        PUSHER_CLUSTER=$(grep "PUSHER_APP_CLUSTER" .env | cut -d'=' -f2)
        echo -e "${GREEN}✅ PUSHER_APP_CLUSTER: $PUSHER_CLUSTER${NC}"
    else
        echo -e "${RED}❌ PUSHER_APP_CLUSTER no encontrada${NC}"
    fi
    
    if grep -q "ENABLE_PUSHER" .env; then
        ENABLE_PUSHER=$(grep "ENABLE_PUSHER" .env | cut -d'=' -f2)
        echo -e "${GREEN}✅ ENABLE_PUSHER: $ENABLE_PUSHER${NC}"
    else
        echo -e "${YELLOW}⚠️ ENABLE_PUSHER no encontrada (usará default)${NC}"
    fi
    
    if grep -q "API_URL_LOCAL" .env; then
        API_LOCAL=$(grep "API_URL_LOCAL" .env | cut -d'=' -f2)
        echo -e "${GREEN}✅ API_URL_LOCAL: $API_LOCAL${NC}"
    else
        echo -e "${RED}❌ API_URL_LOCAL no encontrada${NC}"
    fi
    
    if grep -q "API_URL_PROD" .env; then
        API_PROD=$(grep "API_URL_PROD" .env | cut -d'=' -f2)
        echo -e "${GREEN}✅ API_URL_PROD: $API_PROD${NC}"
    else
        echo -e "${RED}❌ API_URL_PROD no encontrada${NC}"
    fi
else
    echo -e "${RED}❌ .env no existe${NC}"
fi

echo ""
echo "2️⃣ VERIFICANDO BACKEND (Laravel)"
echo "--------------------------------"

cd ../CorralX-Backend 2>/dev/null || { echo -e "${RED}❌ No se puede acceder al backend${NC}"; exit 1; }

# Verificar configuración de Pusher en backend
echo ""
echo "Configuración de Pusher:"
PUSHER_KEY_BACKEND=$(php artisan tinker --execute="echo config('broadcasting.connections.pusher.key');" 2>/dev/null | tail -1)
PUSHER_CLUSTER_BACKEND=$(php artisan tinker --execute="echo config('broadcasting.connections.pusher.options.cluster');" 2>/dev/null | tail -1)
BROADCAST_DRIVER=$(php artisan tinker --execute="echo config('broadcasting.default');" 2>/dev/null | tail -1)

if [ ! -z "$PUSHER_KEY_BACKEND" ]; then
    echo -e "${GREEN}✅ Backend PUSHER_APP_KEY: ${PUSHER_KEY_BACKEND:0:10}...${NC}"
else
    echo -e "${RED}❌ Backend PUSHER_APP_KEY no configurada${NC}"
fi

if [ ! -z "$PUSHER_CLUSTER_BACKEND" ]; then
    echo -e "${GREEN}✅ Backend PUSHER_APP_CLUSTER: $PUSHER_CLUSTER_BACKEND${NC}"
else
    echo -e "${RED}❌ Backend PUSHER_APP_CLUSTER no configurada${NC}"
fi

if [ ! -z "$BROADCAST_DRIVER" ]; then
    echo -e "${GREEN}✅ BROADCAST_DRIVER: $BROADCAST_DRIVER${NC}"
else
    echo -e "${YELLOW}⚠️ BROADCAST_DRIVER no configurado${NC}"
fi

# Comparar credenciales
echo ""
echo "3️⃣ COMPARACIÓN FRONTEND vs BACKEND"
echo "-----------------------------------"

cd ../CorralX-Frontend 2>/dev/null || exit 1

if [ ! -z "$PUSHER_KEY" ] && [ ! -z "$PUSHER_KEY_BACKEND" ]; then
    if [ "$PUSHER_KEY" == "$PUSHER_KEY_BACKEND" ]; then
        echo -e "${GREEN}✅ PUSHER_APP_KEY coincide entre frontend y backend${NC}"
    else
        echo -e "${RED}❌ PUSHER_APP_KEY NO coincide${NC}"
        echo -e "${YELLOW}   Frontend: ${PUSHER_KEY:0:10}...${NC}"
        echo -e "${YELLOW}   Backend:  ${PUSHER_KEY_BACKEND:0:10}...${NC}"
        echo -e "${YELLOW}   ⚠️ IMPORTANTE: Deben ser iguales para que funcione el chat${NC}"
    fi
fi

if [ ! -z "$PUSHER_CLUSTER" ] && [ ! -z "$PUSHER_CLUSTER_BACKEND" ]; then
    if [ "$PUSHER_CLUSTER" == "$PUSHER_CLUSTER_BACKEND" ]; then
        echo -e "${GREEN}✅ PUSHER_APP_CLUSTER coincide entre frontend y backend${NC}"
    else
        echo -e "${RED}❌ PUSHER_APP_CLUSTER NO coincide${NC}"
        echo -e "${YELLOW}   Frontend: $PUSHER_CLUSTER${NC}"
        echo -e "${YELLOW}   Backend:  $PUSHER_CLUSTER_BACKEND${NC}"
    fi
fi

# Verificar Firebase
echo ""
echo "4️⃣ VERIFICANDO FIREBASE"
echo "------------------------"

if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ google-services.json existe${NC}"
    
    PROJECT_ID=$(grep -o '"project_id": "[^"]*"' android/app/google-services.json | head -1 | cut -d'"' -f4)
    if [ ! -z "$PROJECT_ID" ]; then
        echo -e "${GREEN}✅ Project ID: $PROJECT_ID${NC}"
    fi
else
    echo -e "${RED}❌ google-services.json NO existe${NC}"
fi

# Verificar archivo de credenciales Firebase en backend
echo ""
echo "Verificando credenciales Firebase en backend..."
cd ../CorralX-Backend 2>/dev/null || exit 1

if [ -f "storage/app/corralx777-firebase-adminsdk-fbsvc-c0fbc31cfc.json" ]; then
    echo -e "${GREEN}✅ Archivo de credenciales Firebase existe en backend${NC}"
else
    echo -e "${YELLOW}⚠️ Archivo de credenciales Firebase no encontrado${NC}"
fi

# Verificar conectividad API
echo ""
echo "5️⃣ VERIFICANDO CONECTIVIDAD API"
echo "--------------------------------"

cd ../CorralX-Frontend 2>/dev/null || exit 1

if [ ! -z "$API_LOCAL" ]; then
    echo "Probando conexión a: $API_LOCAL/api/ping"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$API_LOCAL/api/ping" 2>/dev/null)
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}✅ API Local responde correctamente (HTTP $HTTP_CODE)${NC}"
    elif [ "$HTTP_CODE" == "000" ]; then
        echo -e "${RED}❌ API Local no responde (sin conexión)${NC}"
    else
        echo -e "${YELLOW}⚠️ API Local responde con código HTTP $HTTP_CODE${NC}"
    fi
fi

echo ""
echo "=================================================="
echo "✅ Verificación completada"
echo ""

