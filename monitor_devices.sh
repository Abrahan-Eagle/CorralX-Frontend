#!/bin/bash

# Script para monitorear los logs de ambos dispositivos en tiempo real
# Muestra errores y advertencias destacadas

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Monitoreando logs de ambos dispositivos...${NC}"
echo -e "${YELLOW}   Presiona Ctrl+C para detener${NC}"
echo ""

LOG1=$(ls -t logs/device1_*.log 2>/dev/null | head -1)
LOG2=$(ls -t logs/device2_*.log 2>/dev/null | head -1)

if [ -z "$LOG1" ] || [ -z "$LOG2" ]; then
    echo -e "${YELLOW}⏳ Esperando que se generen los archivos de log...${NC}"
    sleep 3
    LOG1=$(ls -t logs/device1_*.log 2>/dev/null | head -1)
    LOG2=$(ls -t logs/device2_*.log 2>/dev/null | head -1)
fi

if [ -z "$LOG1" ] || [ -z "$LOG2" ]; then
    echo -e "${RED}❌ No se encontraron archivos de log${NC}"
    exit 1
fi

echo -e "${GREEN}📝 Device 1 log: $LOG1${NC}"
echo -e "${BLUE}📝 Device 2 log: $LOG2${NC}"
echo ""

# Función para destacar errores
highlight_errors() {
    sed -E \
        -e "s/(ERROR|Error|error)/${RED}\1${NC}/g" \
        -e "s/(WARNING|Warning|warning)/${YELLOW}\1${NC}/g" \
        -e "s/(✅|SUCCESS|Success)/${GREEN}\1${NC}/g" \
        -e "s/(❌|FAILED|Failed)/${RED}\1${NC}/g"
}

# Monitorear ambos logs en paralelo usando tail
tail -f "$LOG1" "$LOG2" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -q "\[DEVICE 1\]"; then
        echo -e "${GREEN}$line${NC}" | highlight_errors
    elif echo "$line" | grep -q "\[DEVICE 2\]"; then
        echo -e "${BLUE}$line${NC}" | highlight_errors
    else
        echo "$line" | highlight_errors
    fi
done

