#!/bin/bash

# Script mejorado para compilar en dos dispositivos
# Solución: Compilar primero en un dispositivo, luego iniciar el segundo en modo hot-reload

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DEVICE1="192.168.27.8:5555"
DEVICE2="192.168.27.5:5555"

echo -e "${GREEN}🚀 Compilando en DOS dispositivos (secuencial para evitar conflictos)${NC}"
echo -e "${BLUE}   Dispositivo 1: $DEVICE1${NC}"
echo -e "${BLUE}   Dispositivo 2: $DEVICE2${NC}"
echo ""

mkdir -p logs
LOG1="logs/device1_$(date +%Y%m%d_%H%M%S).log"
LOG2="logs/device2_$(date +%Y%m%d_%H%M%S).log"

# Función para Device 1 - Compilación completa
run_device1() {
    echo -e "${GREEN}[DEVICE 1]${NC} Compilando..." | tee "$LOG1"
    flutter run -d $DEVICE1 2>&1 | while IFS= read -r line; do
        echo -e "${GREEN}[DEVICE 1]${NC} $line" | tee -a "$LOG1"
    done
}

# Función para Device 2 - Inicia después de que Device 1 termine la compilación
run_device2() {
    echo -e "${BLUE}[DEVICE 2]${NC} Esperando a que Device 1 compile..." | tee "$LOG2"
    # Esperar a que Device 1 termine la compilación inicial (máximo 5 minutos)
    for i in {1..300}; do
        if tail -20 "$LOG1" 2>/dev/null | grep -q "Built\|Running"; then
            echo -e "${BLUE}[DEVICE 2]${NC} Device 1 compiló, iniciando Device 2..." | tee -a "$LOG2"
            break
        fi
        sleep 1
    done
    
    # Pequeña espera adicional para asegurar que los archivos no estén bloqueados
    sleep 5
    
    echo -e "${BLUE}[DEVICE 2]${NC} Compilando..." | tee -a "$LOG2"
    flutter run -d $DEVICE2 2>&1 | while IFS= read -r line; do
        echo -e "${BLUE}[DEVICE 2]${NC} $line" | tee -a "$LOG2"
    done
}

# Iniciar Device 1 en segundo plano
run_device1 &
PID1=$!
echo -e "${GREEN}✅ Device 1 iniciado (PID: $PID1)${NC}"

# Iniciar Device 2 después de un pequeño delay
sleep 10
run_device2 &
PID2=$!
echo -e "${BLUE}✅ Device 2 iniciado (PID: $PID2)${NC}"

echo ""
echo -e "${YELLOW}📊 Monitoreando ambos procesos...${NC}"
echo -e "${GREEN}   Device 1 PID: $PID1${NC}"
echo -e "${BLUE}   Device 2 PID: $PID2${NC}"
echo ""
echo -e "${YELLOW}📝 Logs:${NC}"
echo -e "   Device 1: $LOG1"
echo -e "   Device 2: $LOG2"
echo ""
echo -e "${YELLOW}🛑 Presiona Ctrl+C para detener ambos${NC}"
echo ""

# Esperar a que ambos terminen
wait $PID1
wait $PID2

