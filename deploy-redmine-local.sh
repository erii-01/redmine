#!/bin/bash

# Capturar tiempo de inicio
START_TIME=$(date +%s)

# --- Configuración ---
ANSIBLE_DIR="BETA-redmineAnsible"
ANSIBLE_PLAYBOOK="playbook-vagrant.yml"
VAULT_PASS_FILE=".vault_pass"
VAGRANTFILE_DIR="BETA-redmineAnsible"

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

# --- Paso 1: Aprovisionar VM con Vagrant ---
echo "--- Paso 1: Aprovisionando VM con Vagrant ---"
cd "$VAGRANTFILE_DIR" || { echo "ERROR: No se pudo cambiar al directorio $VAGRANTFILE_DIR"; exit 1; }

# Verificar si Vagrant está instalado
if ! command -v vagrant &> /dev/null; then
    echo "ERROR: Vagrant no está instalado. Instálalo desde https://www.vagrantup.com/"
    exit 1
fi

# Verificar si VirtualBox está instalado
if ! command -v VBoxManage &> /dev/null; then
    echo "ERROR: VirtualBox no está instalado. Instálalo desde https://www.virtualbox.org/"
    exit 1
fi

echo ">> Iniciando VM con Vagrant..."
vagrant up
if [ $? -ne 0 ]; then
    echo "ERROR: Falló el aprovisionamiento de la VM con Vagrant."
    exit 1
fi

echo "--- Vagrant ha terminado de aprovisionar la VM. ---"

# --- Paso 2: Configurar Aplicación con Ansible ---
echo "--- Paso 2: Configurando Redmine con Ansible ---"

# --- Instalar roles de Ansible Galaxy ---
echo ">> Instalando roles de Ansible Galaxy..."
ansible-galaxy install -r requirements.yml
if [ $? -ne 0 ]; then
    echo "ERROR: Falló la instalación de roles de Ansible Galaxy."
    exit 1
fi

# --- Crear el archivo de contraseña temporal ---
echo ">> Creando archivo de contraseña temporal para Ansible Vault..."
echo "$VAULT_PASS" > "$VAULT_PASS_FILE"
chmod 600 "$VAULT_PASS_FILE"

# Debug: verificar que el archivo se creó
if [ -f "$VAULT_PASS_FILE" ]; then
    echo ">> Archivo de contraseña creado correctamente"
else
    echo "ERROR: No se pudo crear el archivo de contraseña"
    exit 1
fi

echo ">> Ejecutando Playbook de Ansible en la VM local..."
# Usar el inventario local para Vagrant
ansible-playbook "$ANSIBLE_PLAYBOOK" -i inventory/hosts_vagrant.ini.bak --vault-password-file "$VAULT_PASS_FILE" -vvv
ANSIBLE_EXIT_CODE=$?

# --- Limpiar el archivo de contraseña ---
echo ">> Eliminando archivo de contraseña temporal..."
rm -f "$VAULT_PASS_FILE"

if [ $ANSIBLE_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Falló la ejecución del Playbook de Ansible."
    exit 1
fi

# Calcular tiempo transcurrido
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "--- ¡Despliegue local de Redmine completado exitosamente! ---"
echo ">> Tiempo total de despliegue: ${MINUTES}m ${SECONDS}s"
echo ">> Accede a Redmine en: http://192.168.56.101:3000"
echo ">> Para conectarte a la VM: vagrant ssh"