#!/bin/bash

# Script para compilar y ejecutar la app en dos dispositivos simultáneamente
# Útil para probar chat en tiempo real entre dos usuarios

# Colores para distinguir los logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DEVICE1="192.168.27.8:5555"
DEVICE2="192.168.27.5:5555"

echo -e "${GREEN}🚀 Iniciando compilación en DOS dispositivos simultáneamente${NC}"
echo -e "${BLUE}   Dispositivo 1: $DEVICE1${NC}"
echo -e "${BLUE}   Dispositivo 2: $DEVICE2${NC}"
echo ""

# Verificar que los dispositivos estén conectados
echo -e "${YELLOW}🔍 Verificando conexión de dispositivos...${NC}"
if adb connect $DEVICE1 2>&1 | grep -q "connected"; then
    echo -e "${GREEN}✅ Dispositivo 1 conectado${NC}"
else
    echo -e "${YELLOW}⚠️ Dispositivo 1 ya conectado o error${NC}"
fi

if adb connect $DEVICE2 2>&1 | grep -q "connected"; then
    echo -e "${GREEN}✅ Dispositivo 2 conectado${NC}"
else
    echo -e "${YELLOW}⚠️ Dispositivo 2 ya conectado o error${NC}"
fi

echo ""
echo -e "${YELLOW}📱 Iniciando compilación en paralelo...${NC}"
echo -e "${BLUE}   Presiona Ctrl+C para detener ambas instancias${NC}"
echo ""

# Crear directorios temporales para logs
mkdir -p logs
LOG1="logs/device1_$(date +%Y%m%d_%H%M%S).log"
LOG2="logs/device2_$(date +%Y%m%d_%H%M%S).log"

# Función para ejecutar en dispositivo 1
run_device1() {
    echo -e "${GREEN}[DEVICE 1]${NC} Iniciando compilación..." | tee -a "$LOG1"
    flutter run -d $DEVICE1 2>&1 | while IFS= read -r line; do
        echo -e "${GREEN}[DEVICE 1]${NC} $line" | tee -a "$LOG1"
    done
}

# Función para ejecutar en dispositivo 2
run_device2() {
    echo -e "${BLUE}[DEVICE 2]${NC} Iniciando compilación..." | tee -a "$LOG2"
    flutter run -d $DEVICE2 2>&1 | while IFS= read -r line; do
        echo -e "${BLUE}[DEVICE 2]${NC} $line" | tee -a "$LOG2"
    done
}

# Ejecutar ambas instancias en segundo plano
run_device1 &
PID1=$!
echo -e "${GREEN}✅ Proceso Device 1 iniciado (PID: $PID1)${NC}"

# Esperar un poco para que el primer dispositivo comience
sleep 3

run_device2 &
PID2=$!
echo -e "${BLUE}✅ Proceso Device 2 iniciado (PID: $PID2)${NC}"

echo ""
echo -e "${YELLOW}📊 Ambos procesos están ejecutándose${NC}"
echo -e "${GREEN}   Device 1 PID: $PID1${NC}"
echo -e "${BLUE}   Device 2 PID: $PID2${NC}"
echo ""
echo -e "${YELLOW}📝 Logs guardados en:${NC}"
echo -e "   Device 1: $LOG1"
echo -e "   Device 2: $LOG2"
echo ""
echo -e "${YELLOW}🛑 Para detener ambos procesos, presiona Ctrl+C${NC}"
echo ""

# Esperar a que ambos procesos terminen
wait $PID1
wait $PID2

echo ""
echo -e "${YELLOW}✅ Ambos procesos finalizados${NC}"

