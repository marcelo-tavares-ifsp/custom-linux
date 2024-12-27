#!/bin/bash
# restore_home.sh - Restaura os diretórios dos usuários e configurações como nome e ícone.
# Licença: GPLv3
# Autor: Marcelo Tavares de Santana
# Criação: 2024-12-26 

# Array bidimensional: UID, login, nome completo, caminho do ícone.
USERS=(
  "1000 teste 'Usuário de teste' ''"
  # Adicione mais usuários conforme necessário.
)

# Caminho base para backup dos diretórios
BACKUP_BASE="/opt/ifsp/home"

# Função para restaurar o nome completo e o ícone do usuário
restore_user_info() {
  local uid=$1
  local login=$2
  local full_name=$3
  local icon_path=$4

  echo "Restaurando configurações para o usuário $login (UID: $uid)..."

  # Define o nome completo
  busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$uid" \
    org.freedesktop.Accounts.User SetRealName s "$full_name"

  # Define o ícone, ou remove se não existir
  if [[ -f "$icon_path" ]]; then
    busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$uid" \
      org.freedesktop.Accounts.User SetIconFile s "$icon_path"
  else
    echo "Caminho do ícone $icon_path não encontrado. Removendo ícone..."
    busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$uid" \
      org.freedesktop.Accounts.User SetIconFile s ""
  fi

  echo "Removendo senha do usuário $login..."
  passwd -d "$login" 
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
  restore_user_info "$uid" "$login" "$full_name" "$icon_path"
done

echo "Restauração concluída."

