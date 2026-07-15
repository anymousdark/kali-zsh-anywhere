#!/usr/bin/env bash
#
# kali-zsh-anywhere — installer
# Aplica o visual/prompt do Zsh do Kali Linux em qualquer distro compatível.
#
# Uso:
#   ./install.sh              instala para o usuário atual
#   ./install.sh --root       instala também para o root
#   ./install.sh --native     (apenas Debian/Ubuntu/Kali) usa o .zshrc oficial do Kali
#   ./install.sh --uninstall  restaura o backup mais recente
#
# Repositório: kali-zsh-anywhere
set -euo pipefail

# ---------- cores ----------
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
info()  { echo -e "${BLUE}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[x]${NC} $1" >&2; }

# ---------- flags ----------
INSTALL_ROOT=false
FORCE_NATIVE=false
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --root) INSTALL_ROOT=true ;;
    --native) FORCE_NATIVE=true ;;
    --uninstall) UNINSTALL=true ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^#//'
      exit 0
      ;;
    *) warn "Opção desconhecida: $arg" ;;
  esac
done

KALI_DEFAULTS_REPO="https://gitlab.com/kalilinux/packages/kali-defaults.git"
OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# ---------- detectar distro / gerenciador de pacotes ----------
detect_pkg_manager() {
  if command -v apt >/dev/null 2>&1; then echo "apt"
  elif command -v pacman >/dev/null 2>&1; then echo "pacman"
  elif command -v dnf >/dev/null 2>&1; then echo "dnf"
  elif command -v zypper >/dev/null 2>&1; then echo "zypper"
  elif command -v apk >/dev/null 2>&1; then echo "apk"
  else echo "unknown"
  fi
}

PKG_MANAGER=$(detect_pkg_manager)
info "Gerenciador de pacotes detectado: ${PKG_MANAGER}"

is_debian_family() {
  [ "$PKG_MANAGER" = "apt" ]
}

# ---------- instalar dependências base ----------
install_base_deps() {
  info "Instalando dependências base (git, curl, zsh)..."
  case "$PKG_MANAGER" in
    apt)
      sudo apt update -y
      sudo apt install -y git curl zsh fonts-powerline
      ;;
    pacman)
      sudo pacman -Sy --noconfirm git curl zsh powerline-fonts
      ;;
    dnf)
      sudo dnf install -y git curl zsh
      ;;
    zypper)
      sudo zypper install -y git curl zsh
      ;;
    apk)
      sudo apk add --no-cache git curl zsh
      ;;
    *)
      err "Gerenciador de pacotes não reconhecido. Instale manualmente: git, curl, zsh."
      exit 1
      ;;
  esac
  ok "Dependências base instaladas."
}

# ---------- instalar plugins de autosuggestions / syntax-highlighting via pacote nativo (quando existir) ----------
install_native_zsh_plugins() {
  case "$PKG_MANAGER" in
    apt)
      sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
      ;;
    pacman)
      sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
      ;;
    *)
      : # dnf/zypper/apk não têm pacote padrão confiável; cai para o modo git-clone
      ;;
  esac
}

# ---------- backup de um .zshrc existente ----------
backup_zshrc() {
  local home_dir="$1"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  if [ -f "${home_dir}/.zshrc" ]; then
    cp "${home_dir}/.zshrc" "${home_dir}/.zshrc.bak.${ts}"
    ok "Backup criado: ${home_dir}/.zshrc.bak.${ts}"
  fi
}

# ---------- modo 1: .zshrc oficial do Kali (só Debian/Ubuntu/Kali) ----------
install_native_kali_zshrc() {
  local home_dir="$1"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  info "Baixando o .zshrc oficial do Kali..."
  git clone --depth=1 "$KALI_DEFAULTS_REPO" "$tmp_dir" >/dev/null 2>&1

  backup_zshrc "$home_dir"
  cp "${tmp_dir}/etc/skel/.zshrc" "${home_dir}/.zshrc"
  rm -rf "$tmp_dir"
  ok "Arquivo .zshrc oficial do Kali aplicado em ${home_dir}."
}

# ---------- modo 2: oh-my-zsh + tema kali + plugins (qualquer distro) ----------
install_omz_kali_theme() {
  local home_dir="$1"
  local user="$2"
  local omz_dir="${home_dir}/.oh-my-zsh"

  if [ ! -d "$omz_dir" ]; then
    info "Instalando oh-my-zsh para ${user}..."
    export RUNZSH=no
    export CHSH=no
    if [ "$user" = "root" ]; then
      sh -c "$(curl -fsSL "$OMZ_INSTALL_URL")" "" --unattended
    else
      su - "$user" -c "sh -c \"\$(curl -fsSL $OMZ_INSTALL_URL)\" \"\" --unattended"
    fi
    ok "oh-my-zsh instalado."
  else
    warn "oh-my-zsh já está instalado em ${omz_dir}, pulando."
  fi

  backup_zshrc "$home_dir"

  local custom_dir="${omz_dir}/custom"
  local plugins_dir="${custom_dir}/plugins"
  mkdir -p "$plugins_dir"

  for repo_plugin in \
    "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions" \
    "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting" \
    "zsh-completions:https://github.com/zsh-users/zsh-completions"
  do
    local name="${repo_plugin%%:*}"
    local url="${repo_plugin#*:}"
    if [ ! -d "${plugins_dir}/${name}" ]; then
      info "Clonando plugin ${name}..."
      git clone --depth=1 "$url" "${plugins_dir}/${name}" >/dev/null 2>&1
    else
      warn "Plugin ${name} já existe, pulando."
    fi
  done

  # gera um .zshrc baseado no template padrão do oh-my-zsh com tema e plugins do Kali
  cat > "${home_dir}/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="kali"

plugins=(
  git
  sudo
  colored-man-pages
  command-not-found
  extract
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# zsh-syntax-highlighting precisa ser carregado por último (já garantido pela ordem acima)
EOF

  ok "oh-my-zsh configurado com tema 'kali' e plugins em ${home_dir}."
}

# ---------- ajustar dono dos arquivos + shell padrão ----------
finalize_user() {
  local user="$1"
  local home_dir="$2"

  chown -R "${user}:${user}" "${home_dir}/.zshrc" 2>/dev/null || true
  if [ -d "${home_dir}/.oh-my-zsh" ]; then
    chown -R "${user}:${user}" "${home_dir}/.oh-my-zsh" 2>/dev/null || true
  fi

  local zsh_path
  zsh_path=$(command -v zsh)
  if [ "$(getent passwd "$user" | cut -d: -f7)" != "$zsh_path" ]; then
    info "Definindo zsh como shell padrão de ${user}..."
    chsh -s "$zsh_path" "$user"
  fi
}

# ---------- desinstalar / restaurar backup ----------
do_uninstall() {
  local home_dir="$1"
  local last_backup
  last_backup=$(ls -t "${home_dir}"/.zshrc.bak.* 2>/dev/null | head -n1 || true)
  if [ -z "$last_backup" ]; then
    err "Nenhum backup encontrado em ${home_dir}."
    return 1
  fi
  cp "$last_backup" "${home_dir}/.zshrc"
  ok "Restaurado: ${last_backup} -> ${home_dir}/.zshrc"
}

# ---------- fluxo principal para um usuário específico ----------
run_for_user() {
  local user="$1"
  local home_dir
  home_dir=$(getent passwd "$user" | cut -d: -f6)

  if [ "$UNINSTALL" = true ]; then
    do_uninstall "$home_dir"
    return
  fi

  if [ "$FORCE_NATIVE" = true ] && is_debian_family; then
    install_native_kali_zshrc "$home_dir"
  elif [ "$FORCE_NATIVE" = true ] && ! is_debian_family; then
    warn "--native só funciona em Debian/Ubuntu/Kali. Usando o modo oh-my-zsh."
    install_omz_kali_theme "$home_dir" "$user"
  else
    install_omz_kali_theme "$home_dir" "$user"
  fi

  finalize_user "$user" "$home_dir"
}

# ---------- execução ----------
main() {
  install_base_deps
  install_native_zsh_plugins

  CURRENT_USER=$(logname 2>/dev/null || echo "$SUDO_USER" || whoami)
  run_for_user "$CURRENT_USER"

  if [ "$INSTALL_ROOT" = true ]; then
    info "Aplicando também para o root..."
    if [ "$UID" -ne 0 ] && [ "$UNINSTALL" = false ]; then
      sudo bash -c "$(declare -f install_base_deps install_native_zsh_plugins backup_zshrc install_native_kali_zshrc install_omz_kali_theme finalize_user do_uninstall run_for_user); \
        PKG_MANAGER='$PKG_MANAGER'; KALI_DEFAULTS_REPO='$KALI_DEFAULTS_REPO'; OMZ_INSTALL_URL='$OMZ_INSTALL_URL'; \
        FORCE_NATIVE=$FORCE_NATIVE; UNINSTALL=$UNINSTALL; \
        run_for_user root"
    else
      run_for_user root
    fi
  fi

  echo
  ok "Concluído! Abra um novo terminal (ou rode 'zsh') para ver o resultado."
  if [ "$INSTALL_ROOT" = true ]; then
    ok "Para testar como root: sudo -i"
  fi
}

main
