#!/bin/bash

# Capturar tiempo de inicio
START_TIME=$(date +%s)

# --- Configuración ---
ANSIBLE_DIR="BETA-redmineAnsible"
INFRA_DIR="infra"
ANSIBLE_PLAYBOOK="playbook-aws.yml"
VAULT_PASS_FILE=".vault_pass"

# Obtener pass de Ansible vault
echo ">> Se necesita la contraseña de Ansible Vault para continuar."
read -s -p ">> Introduce la contraseña de Vault y presiona Enter: " VAULT_PASS
echo
if [ -z "$VAULT_PASS" ]; then
    echo "ERROR: No se introdujo una contraseña de Vault."
    exit 1
fi



# Activar entorno virtual de Ansible
echo ">> Activando entorno virtual de Ansible..."
source ./.venv/bin/activate || { echo "ERROR: No se pudo activar el entorno virtual de Ansible."; exit 1; }
echo ">> Entorno virtual activado."

# --Descomentar las siguientes dos lineas si  la clave SSH (si tienes passphrase) --
#echo ">> Iniciando agente SSH y añadiendo clave (si tienes passphrase)..."
#eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_ed25519 
if [ $? -ne 0 ]; then
    echo "ERROR: No se pudo añadir la clave SSH al agente. Asegúrate que la clave exista y la passphrase sea correcta (si aplica)."
    exit 1
fi
echo ">> Agente SSH configurado."

# --- Paso 1: Aprovisionar Infraestructura ---
echo "--- Paso 1: Aprovisionando infraestructura con Terraform ---"
cd "$INFRA_DIR" || { echo "ERROR: No se pudo cambiar al directorio $INFRA_DIR"; exit 1; }

# Inicializar Terraform (si no se ha hecho o si hay cambios en los providers)
echo ">> Inicializando Terraform..."
terraform init
if [ $? -ne 0 ]; then
Terraform    exit 1
fi

# Aplicar la configuración de Terraform
echo ">> Aplicando configuración de Terraform (creando EC2, RDS, etc.)..."
terraform apply -auto-approve
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la aplicación de Terraform."
    exit 1
fi

echo "--- Terraform ha terminado de aprovisionar la infraestructura. ---"

# --- Volver al directorio raíz del proyecto ---
cd ../ # Volver a 'redmine-aws/'

# --- Paso 2: Configurar Aplicación con Ansible ---
echo "--- Paso 2: Configurando Redmine con Ansible ---"
cd "$ANSIBLE_DIR" || { echo "ERROR: No se pudo cambiar al directorio $ANSIBLE_DIR"; exit 1; }


# --- Crear el archivo de contraseña temporal ---
echo ">> Creando archivo de contraseña temporal para Ansible Vault..."
echo "$VAULT_PASS" > "$VAULT_PASS_FILE"
chmod 600 "$VAULT_PASS_FILE"


echo ">> Ejecutando Playbook de Ansible..."
# Ejecutamos el playbook. El inventario se lee de ansible.cfg
ansible-playbook "$ANSIBLE_PLAYBOOK" --vault-password-file "$VAULT_PASS_FILE" -vvv # -vvv para ver detalles de depuración
ANSIBLE_EXIT_CODE=$? # Guardar el código de salida de Ansible

# --- Limpiar el archivo de contraseña, sin importar si Ansible falló o no ---
echo ">> Eliminando archivo de contraseña temporal..."
rm -f "$VAULT_PASS_FILE"

if [ $? -ne 0 ]; then
    echo "ERROR: Falló la ejecución del Playbook de Ansible."
    exit 1
fi

# Calcular tiempo transcurrido
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "--- ¡Despliegue de Redmine completado exitosamente! ---"
echo ">> Tiempo total de despliegue: ${MINUTES}m ${SECONDS}s"

# --- Opcional: Detener agente SSH si se inició aquí ---
# echo ">> Deteniendo agente SSH (si se inició por el script)..."
# ssh-agent -k