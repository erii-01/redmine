#!/bin/bash

# --- Configuración ---
VAGRANTFILE_DIR="BETA-redmineAnsible"

echo "--- Destruyendo entorno local de Redmine ---"
cd "$VAGRANTFILE_DIR" || { echo "ERROR: No se pudo cambiar al directorio $VAGRANTFILE_DIR"; exit 1; }

# Verificar si Vagrant está instalado
if ! command -v vagrant &> /dev/null; then
    echo "ERROR: Vagrant no está instalado."
    exit 1
fi

echo ">> Destruyendo VM con Vagrant..."
vagrant destroy -f
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la destrucción de la VM."
    exit 1
fi

echo "--- ¡Entorno local destruido exitosamente! ---"