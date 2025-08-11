#!/bin/bash

# --- Configuración ---
INFRA_DIR="infra"

echo "--- Iniciando proceso de destrucción de la infraestructura de Redmine ---"

# --- Paso 1: Ir al directorio de Terraform ---
echo ">> Navegando al directorio de Terraform: $INFRA_DIR"
cd "$INFRA_DIR" || { echo "ERROR: No se pudo cambiar al directorio $INFRA_DIR"; exit 1; }

# --- Paso 2: Destruir la infraestructura con Terraform ---
echo ">> Ejecutando 'terraform destroy'. Esto eliminará todos los recursos de AWS."
echo ">> Se requerirá confirmación manual, escribe 'yes' cuando se te solicite."
terraform destroy
if [ $? -ne 0 ]; then
    echo "ERROR: Falló el comando 'terraform destroy'."
    exit 1
fi

echo "--- Destrucción de la infraestructura completada exitosamente. ---"

# --- Volver al directorio raíz del proyecto ---
cd ../ || { echo "ERROR: No se pudo volver al directorio raíz."; exit 1; }