#!/bin/bash

# Script SIMPLE para ejecutar en dos terminales separadas
# Ejecuta este script dos veces, una para cada dispositivo

DEVICE1="192.168.27.8:5555"
DEVICE2="192.168.27.5:5555"

# Determinar dispositivo según argumento
if [ "$1" == "1" ] || [ "$1" == "" ]; then
    DEVICE=$DEVICE1
    COLOR="\033[0;32m"
    LABEL="[DEVICE 1]"
elif [ "$1" == "2" ]; then
    DEVICE=$DEVICE2
    COLOR="\033[0;34m"
    LABEL="[DEVICE 2]"
else
    echo "Uso: $0 [1|2]"
    echo "  1 = Dispositivo 1 ($DEVICE1)"
    echo "  2 = Dispositivo 2 ($DEVICE2)"
    exit 1
fi

echo -e "${COLOR}${LABEL} Conectando a $DEVICE${NC}"
adb connect $DEVICE

echo -e "${COLOR}${LABEL} Compilando y ejecutando...${NC}"
echo -e "${COLOR}${LABEL} Presiona Ctrl+C para detener${NC}"
echo ""

flutter run -d $DEVICE 2>&1 | while IFS= read -r line; do
    echo -e "${COLOR}${LABEL}${NC} $line"
done

