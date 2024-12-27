#!/bin/bash
# restore_home.sh - Restaura os diretórios dos usuários e configurações como nome e ícone.
# Licença: GPLv3
# Autor: [Seu Nome]
# Data: [Data de Criação]

# Array bidimensional: UID, login, nome completo, caminho do ícone.
USERS=(
  "1000 teste 'Usuário de teste' ''"
  # Adicione mais usuários conforme necessário.
)

# Caminho base para backup dos diretórios
BACKUP_BASE="/opt/ifsp/home"

# Função para restaurar o diretório do usuário
restore_directory() {
  local login=$1
  rsync -a --delete "$BACKUP_BASE/$login/" "/home/$login/"
}

# Itera sobre os usuários no array
for user_info in "${USERS[@]}"; do
  # Divide as informações do usuário, tratando o nome completo com cuidado
  eval "set -- $user_info"
  uid=$1
  login=$2
  full_name=$3
  icon_path=$4

  # Remove as aspas do nome completo para chamadas posteriores
  full_name=${full_name//\'/}

  # Restaura diretório e informações do usuário
  restore_directory "$login"
done

echo "Restauração concluída."

