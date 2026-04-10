#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()    { echo -e "${CYAN}➡️  $*${RESET}"; }
success() { echo -e "${GREEN}✔  $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠  $*${RESET}"; }
error()   { echo -e "${RED}✖  $*${RESET}" >&2; }
abort()   { error "$*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIT_SOURCE="$SCRIPT_DIR/.nit"
INSTALL_DIR="/usr/local/bin"
INSTALL_PATH="$INSTALL_DIR/nit"

echo -e "\n${BOLD}${CYAN}nit${RESET} ${DIM}— instalador${RESET}\n"

# ========================
# Verificações
# ========================

[[ -f "$NIT_SOURCE" ]] || abort "Arquivo .nit não encontrado em: $SCRIPT_DIR"

command -v git > /dev/null 2>&1 || abort "git não está instalado. Instale git antes de continuar."

command -v bash > /dev/null 2>&1 || abort "bash não está disponível."

BASH_VERSION_MAJOR="${BASH_VERSINFO[0]}"
if [[ "$BASH_VERSION_MAJOR" -lt 4 ]]; then
  warn "bash $BASH_VERSION detectado. Recomendado: bash 4+."
  warn "No macOS, instale via: brew install bash"
fi

# ========================
# Verificar diretório de instalação
# ========================

if [[ ! -d "$INSTALL_DIR" ]]; then
  warn "$INSTALL_DIR não existe. Tentando criar..."
  mkdir -p "$INSTALL_DIR" 2>/dev/null || abort "Não foi possível criar $INSTALL_DIR. Tente com sudo."
fi

if [[ ! -w "$INSTALL_DIR" ]]; then
  warn "Sem permissão de escrita em $INSTALL_DIR."
  info "Tentando instalar com sudo..."
  sudo cp "$NIT_SOURCE" "$INSTALL_PATH"
  sudo chmod +x "$INSTALL_PATH"
else
  cp "$NIT_SOURCE" "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"
fi

# ========================
# Verificar se está no PATH
# ========================

if ! command -v nit > /dev/null 2>&1; then
  warn "'nit' não foi encontrado no PATH após a instalação."
  warn "Adicione $INSTALL_DIR ao seu PATH:"
  echo -e "  ${DIM}export PATH=\"\$PATH:$INSTALL_DIR\"${RESET}"
  warn "Ou reinicie o terminal."
else
  echo ""
  success "nit instalado com sucesso em $INSTALL_PATH"
  echo -e "  ${DIM}Versão:${RESET} $(nit --version 2>/dev/null || echo "n/a")"
  echo -e "\n${DIM}Execute 'nit' para ver os comandos disponíveis.${RESET}\n"
fi
