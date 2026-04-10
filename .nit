#!/usr/bin/env bash

# ========================
# Cores
# ========================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ========================
# Helpers
# ========================

ask() {
  printf "  ${CYAN}?${RESET} ${BOLD}$1${RESET} ${DIM}›${RESET} " >&2
  read -r value
  echo "$value"
}

confirm() {
  printf "  ${YELLOW}?${RESET} ${BOLD}$1${RESET} ${DIM}[y/N]${RESET} " >&2
  read -r yn
  [[ "$yn" == "y" || "$yn" == "Y" ]]
}

info()    { echo -e "  ${BLUE}→${RESET} $*"; }
success() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET} ${YELLOW}$*${RESET}"; }
error()   { echo -e "  ${RED}✗${RESET} ${RED}$*${RESET}" >&2; }
abort()   { error "$*"; exit 1; }

sep()     { echo -e "  ${DIM}────────────────────────────────${RESET}"; }
label()   { echo -e "\n  ${BOLD}$*${RESET}"; }
header()  {
  echo ""
  echo -e "  ${DIM}┌─${RESET} ${BOLD}nit${RESET} ${CYAN}$*${RESET}"
  sep
}

require_git_repo() {
  git rev-parse --git-dir > /dev/null 2>&1 || {
    echo -e "\n  ${RED}✗${RESET} ${RED}Não é um repositório git.${RESET}"
    echo -e "  ${DIM}Dica: use ${RESET}nit init${DIM} para iniciar um novo repositório.${RESET}\n"
    exit 1
  }
}

is_git_repo() {
  git rev-parse --git-dir > /dev/null 2>&1
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

get_current_branch() {
  git branch --show-current
}

get_scope_from_branch() {
  local branch
  branch=$(get_current_branch)
  if [[ "$branch" == *"/"* ]]; then
    echo "$branch" | cut -d '/' -f2 | cut -d '-' -f1
  fi
}

# ========================
# Branch
# ========================

branch_flow() {
  local type="$1"
  shift
  local name
  name=$(slugify "$*")

  if [[ -z "$type" ]] || [[ -z "$name" ]]; then
    abort "Uso: nit branch <tipo> <nome>  →  ex: nit branch feat login-flow"
  fi

  local branch="$type/$name"
  header "branch"
  info "Tipo:   ${DIM}$type${RESET}"
  info "Nome:   ${BOLD}${CYAN}$branch${RESET}"
  echo ""
  git checkout -b "$branch" && success "Branch criada e ativa."
}

# ========================
# Commit semântico
# ========================

commit_flow() {
  local type="$1"
  local issue="$2"
  local desc="$3"
  local msg scope

  header "$type"

  if [[ -z "$desc" && -z "$issue" ]]; then
    scope=$(ask "Escopo")
    desc=$(ask "Descrição")
    [[ -z "$desc" ]] && abort "Descrição não pode ser vazia."
    msg="$type($scope): $desc"

  elif [[ -z "$desc" ]]; then
    msg="$type: $issue"

  else
    scope=$(get_scope_from_branch)
    [[ -z "$scope" ]] && scope=$(ask "Escopo")
    msg="$type($scope): $issue $desc"
  fi

  echo ""
  info "Mensagem: ${BOLD}${CYAN}$msg${RESET}"
  echo ""
  info "Adicionando arquivos..."
  git add .
  info "Criando commit..."
  git commit -m "$msg"
  success "Commit criado."
  echo ""

  if confirm "Fazer push agora?"; then
    echo ""
    push_flow
  fi
}

# ========================
# WIP (work in progress)
# ========================

wip_flow() {
  local branch
  branch=$(get_current_branch)
  header "wip"
  info "Branch: ${BOLD}${CYAN}$branch${RESET}"
  echo ""
  warn "Este commit será marcado como trabalho em progresso."
  echo ""
  info "Adicionando arquivos..."
  git add .
  info "Criando commit WIP..."
  git commit -m "wip: trabalho em progresso"
  success "WIP salvo."
}

# ========================
# Amend
# ========================

amend_flow() {
  local choice last_msg
  last_msg=$(git log -1 --pretty=%s)
  header "amend"
  info "Último commit: ${BOLD}$last_msg${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET} Alterar mensagem"
  echo -e "  ${CYAN}[2]${RESET} Adicionar arquivos staged ${DIM}(mantém mensagem)${RESET}"
  echo ""
  choice=$(ask "Opção")

  case "$choice" in
    1)
      local msg
      msg=$(ask "Nova mensagem")
      [[ -z "$msg" ]] && abort "Mensagem não pode ser vazia."
      git add .
      git commit --amend -m "$msg"
      success "Commit atualizado."
      ;;
    2)
      git add .
      git commit --amend --no-edit
      success "Arquivos adicionados ao último commit."
      ;;
    *)
      abort "Opção inválida."
      ;;
  esac
}

# ========================
# Undo (desfaz último commit)
# ========================

undo_flow() {
  local last_msg
  last_msg=$(git log -1 --pretty=%s)
  header "undo"
  warn "Desfazendo: ${BOLD}$last_msg${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET} soft  ${DIM}— mantém alterações staged${RESET}"
  echo -e "  ${CYAN}[2]${RESET} mixed ${DIM}— mantém alterações unstaged${RESET}"
  echo -e "  ${RED}[3]${RESET} hard  ${DIM}— descarta tudo permanentemente${RESET}"
  echo ""
  local choice
  choice=$(ask "Modo")

  case "$choice" in
    1) git reset --soft HEAD~1 && success "Commit desfeito ${DIM}(soft)${RESET}." ;;
    2) git reset --mixed HEAD~1 && success "Commit desfeito ${DIM}(mixed)${RESET}." ;;
    3)
      confirm "Isso vai descartar todas as alterações. Tem certeza?" \
        && git reset --hard HEAD~1 && success "Commit desfeito ${DIM}(hard)${RESET}."
      ;;
    *) abort "Opção inválida." ;;
  esac
}

# ========================
# Cherry pick assistido
# ========================

cherry_pick_flow() {
  header "cherry"
  info "Últimos 15 commits:"
  echo ""
  git log --oneline -15
  echo ""
  local hash
  hash=$(ask "Hash do commit")
  [[ -z "$hash" ]] && abort "Hash não pode ser vazio."
  echo ""
  info "Aplicando cherry-pick: ${BOLD}${CYAN}$hash${RESET}"
  git cherry-pick "$hash" && success "Cherry-pick aplicado com sucesso."
}

# ========================
# Reset seguro
# ========================

reset_flow() {
  header "reset"
  warn "Esta operação altera o histórico de commits."
  echo ""
  echo -e "  ${CYAN}[1]${RESET} soft  ${DIM}— mantém alterações staged${RESET}"
  echo -e "  ${CYAN}[2]${RESET} mixed ${DIM}— mantém alterações unstaged${RESET}"
  echo -e "  ${RED}[3]${RESET} hard  ${DIM}— descarta tudo permanentemente${RESET}"
  echo ""
  local type hash
  type=$(ask "Modo")
  hash=$(ask "Hash ou referência ${DIM}(ex: HEAD~1)${RESET}")
  [[ -z "$hash" ]] && abort "Referência não pode ser vazia."

  case "$type" in
    1) git reset --soft "$hash" && success "Reset soft aplicado." ;;
    2) git reset --mixed "$hash" && success "Reset mixed aplicado." ;;
    3)
      confirm "Isso vai apagar todas as alterações. Tem certeza?" \
        && git reset --hard "$hash" && success "Reset hard aplicado."
      ;;
    *) abort "Opção inválida." ;;
  esac
}

# ========================
# Revert
# ========================

revert_flow() {
  header "revert"
  info "Cria um novo commit que desfaz as mudanças do commit selecionado."
  info "Últimos 15 commits:"
  echo ""
  git log --oneline -15
  echo ""
  local hash
  hash=$(ask "Hash para reverter")
  [[ -z "$hash" ]] && abort "Hash não pode ser vazio."
  echo ""
  info "Revertendo: ${BOLD}${CYAN}$hash${RESET}"
  git revert "$hash" && success "Revert aplicado."
}

# ========================
# Diff
# ========================

diff_flow() {
  local staged="${1:-}"

  if [[ "$staged" == "--staged" || "$staged" == "-s" ]]; then
    header "diff --staged"
    info "Alterações prontas para commit ${DIM}(staged)${RESET}"
    echo ""
    git diff --staged
  else
    header "diff"
    info "Alterações ainda não adicionadas ${DIM}(unstaged)${RESET}"
    echo ""
    git diff
    echo ""
    echo -e "  ${DIM}┌ dica: use ${RESET}nit diff --staged${DIM} para ver o que será commitado${RESET}"
  fi
}

# ========================
# Stash
# ========================

stash_flow() {
  local sub="${1:-}"

  case "$sub" in
    save|"")
      header "stash save"
      info "Salva as alterações atuais sem commitar."
      echo ""
      local msg
      msg=$(ask "Descrição ${DIM}(opcional)${RESET}")
      if [[ -n "$msg" ]]; then
        git stash push -m "$msg"
      else
        git stash push
      fi
      success "Stash salvo."
      ;;
    list|ls)
      header "stash list"
      echo ""
      git stash list || info "Nenhum stash encontrado."
      echo ""
      ;;
    pop)
      header "stash pop"
      info "Restaura um stash e o remove da lista."
      echo ""
      git stash list
      echo ""
      local idx
      idx=$(ask "Índice ${DIM}(Enter para o último)${RESET}")
      echo ""
      if [[ -z "$idx" ]]; then
        git stash pop && success "Stash restaurado."
      else
        git stash pop "stash@{$idx}" && success "Stash $idx restaurado."
      fi
      ;;
    drop)
      header "stash drop"
      warn "O stash selecionado será removido permanentemente."
      echo ""
      git stash list
      echo ""
      local idx
      idx=$(ask "Índice para remover")
      confirm "Remover stash@{$idx}?" && git stash drop "stash@{$idx}" && success "Stash removido."
      ;;
    clear)
      header "stash clear"
      warn "Todos os stashes serão removidos permanentemente."
      echo ""
      confirm "Confirmar?" && git stash clear && success "Stashes removidos."
      ;;
    *)
      error "Subcomando desconhecido: '$sub'"
      echo -e "  ${DIM}Uso: nit stash [save|list|pop|drop|clear]${RESET}\n"
      exit 1
      ;;
  esac
}

# ========================
# Sync (pull + push)
# ========================

sync_flow() {
  local branch
  branch=$(get_current_branch)
  header "sync"
  info "Branch: ${BOLD}${CYAN}$branch${RESET}"
  echo ""
  info "Puxando do remote..."
  git pull origin "$branch" || abort "Falha ao fazer pull."
  info "Enviando para o remote..."
  git push origin "$branch" && success "Branch sincronizada com sucesso."
}

# ========================
# History bonito
# ========================

history_flow() {
  header "history"
  echo ""
  git log --graph --oneline --decorate --all
  echo ""
}

# ========================
# Push inteligente
# ========================

push_flow() {
  local branch
  branch=$(get_current_branch)
  header "push"
  info "Branch: ${BOLD}${CYAN}$branch${RESET} → origin"
  echo ""
  git push origin "$branch" && success "Push realizado."
}

# ========================
# Tags
# ========================

tag_flow() {
  local sub="${1:-}"

  case "$sub" in
    list|ls|"")
      header "tag list"
      echo ""
      git tag --sort=-v:refname | head -20 || info "Nenhuma tag encontrada."
      echo ""
      ;;
    create)
      header "tag create"
      local name msg
      name=$(ask "Nome da tag ${DIM}(ex: v1.0.0)${RESET}")
      [[ -z "$name" ]] && abort "Nome não pode ser vazio."
      msg=$(ask "Mensagem anotada ${DIM}(Enter para tag leve)${RESET}")
      if [[ -n "$msg" ]]; then
        git tag -a "$name" -m "$msg"
      else
        git tag "$name"
      fi
      success "Tag ${BOLD}$name${RESET} criada."
      if confirm "Push da tag?"; then
        git push origin "$name" && success "Tag enviada para o remote."
      fi
      ;;
    delete)
      header "tag delete"
      warn "A tag será removida localmente e, opcionalmente, do remote."
      echo ""
      git tag --sort=-v:refname | head -20
      echo ""
      local name
      name=$(ask "Tag para deletar")
      [[ -z "$name" ]] && abort "Nome não pode ser vazio."
      confirm "Deletar tag ${BOLD}$name${RESET}?" && git tag -d "$name" && success "Tag removida localmente."
      if confirm "Remover também do remote?"; then
        git push origin --delete "$name" && success "Tag removida do remote."
      fi
      ;;
    *)
      error "Subcomando desconhecido: '$sub'"
      echo -e "  ${DIM}Uso: nit tag [list|create|delete]${RESET}\n"
      exit 1
      ;;
  esac
}

# ========================
# Clean (remove branches mescladas)
# ========================

clean_flow() {
  local default_branch merged
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  header "clean"
  info "Base: ${BOLD}${CYAN}$default_branch${RESET}"
  echo ""

  merged=$(git branch --merged "$default_branch" \
    | grep -v "^\*" \
    | grep -v "$default_branch" \
    | grep -v "main\|master\|develop")

  if [[ -z "$merged" ]]; then
    success "Nenhuma branch para limpar."
    return
  fi

  warn "Branches já mescladas em ${BOLD}$default_branch${RESET}:"
  echo ""
  echo "$merged" | while read -r b; do
    echo -e "  ${DIM}·${RESET} $b"
  done
  echo ""

  if confirm "Deletar essas branches locais?"; then
    echo "$merged" | xargs git branch -d
    success "Branches removidas."
  fi
}

# ========================
# Info da branch atual
# ========================

info_flow() {
  local branch
  branch=$(get_current_branch)
  header "info"
  sep
  echo -e "  ${BOLD}branch${RESET}   ${CYAN}$branch${RESET}"
  echo -e "  ${BOLD}commit${RESET}   $(git log -1 --pretty=format:"%h${RESET} ${DIM}%s${RESET} ${DIM}(%ar)${RESET}")"
  echo -e "  ${BOLD}autor${RESET}    ${DIM}$(git log -1 --pretty=format:"%an")${RESET}"
  sep
  echo ""
  local status_out
  status_out=$(git status -s)
  if [[ -z "$status_out" ]]; then
    echo -e "  ${GREEN}✓${RESET} Diretório limpo\n"
  else
    echo "$status_out" | while IFS= read -r line; do
      local flag="${line:0:2}"
      local file="${line:3}"
      case "$flag" in
        'M '|'MM') echo -e "  ${YELLOW}M${RESET}  $file" ;;
        ' M')      echo -e "  ${BLUE}M${RESET}  $file" ;;
        'A '|'AM') echo -e "  ${GREEN}A${RESET}  $file" ;;
        'D '|' D') echo -e "  ${RED}D${RESET}  $file" ;;
        '??')      echo -e "  ${DIM}?  $file${RESET}" ;;
        *)         echo -e "  ${DIM}$flag${RESET} $file" ;;
      esac
    done
    echo ""
  fi
}

# ========================
# Init (primeiro push para o GitHub)
# ========================

init_flow() {
  header "init"

  if is_git_repo; then
    warn "Este diretório já é um repositório git."
    echo ""
    if ! confirm "Continuar mesmo assim?"; then
      echo ""
      exit 0
    fi
    echo ""
  fi

  local dir remote desc branch="main"
  dir=$(basename "$(pwd)")

  info "Diretório: ${BOLD}${CYAN}$dir${RESET}"
  echo ""

  desc=$(ask "Mensagem do commit inicial ${DIM}(Enter para 'initial commit')${RESET}")
  [[ -z "$desc" ]] && desc="initial commit"

  remote=$(ask "URL do repositório remoto ${DIM}(ex: git@github.com:user/$dir.git)${RESET}")
  [[ -z "$remote" ]] && abort "URL do remote é obrigatória."

  echo ""
  sep
  info "Iniciando..."

  # git init
  if ! is_git_repo; then
    git init && info "Repositório inicializado."
  fi

  # git add .
  info "Adicionando arquivos..."
  git add .

  # git commit
  info "Criando commit: ${DIM}$desc${RESET}"
  git commit -m "$desc"

  # branch main
  info "Configurando branch principal: ${BOLD}$branch${RESET}"
  git branch -M "$branch"

  # remote
  if git remote get-url origin > /dev/null 2>&1; then
    warn "Remote 'origin' já existe. Atualizando URL..."
    git remote set-url origin "$remote"
  else
    git remote add origin "$remote"
  fi
  info "Remote: ${DIM}$remote${RESET}"

  # push
  info "Enviando para o GitHub..."
  git push -u origin "$branch"

  sep
  success "Projeto publicado!"
  echo -e "  ${DIM}$remote${RESET}"
  echo ""
}

# ========================
# Main
# ========================

# Main precisa de git repo para a maioria dos comandos,
# mas nit init pode rodar em qualquer diretório.
[[ "$1" != "init" ]] && require_git_repo

case "$1" in

  init)
    init_flow
  ;;

  fix|feat|docs|refactor|build|test|chore|perf|ci|temp|adjust|style)
    commit_flow "$1" "$2" "$3"
  ;;

  branch)
    shift
    if [[ $# -eq 0 ]]; then
      header "branch"
      echo ""
      git branch
      echo ""
    else
      branch_flow "$@"
    fi
  ;;

  wip)
    wip_flow
  ;;

  amend)
    amend_flow
  ;;

  undo)
    undo_flow
  ;;

  commit)
    commit_flow "chore" "$2"
  ;;

  push)
    push_flow
  ;;

  pull)
    header "pull"
    local branch
    branch=$(git branch --show-current)
    info "Branch: ${BOLD}${CYAN}$branch${RESET} ← origin"
    echo ""
    git pull && success "Pull realizado."
  ;;

  sync)
    sync_flow
  ;;

  cherry)
    cherry_pick_flow
  ;;

  diff)
    diff_flow "$2"
  ;;

  stash)
    stash_flow "$2"
  ;;

  reset)
    reset_flow
  ;;

  revert)
    revert_flow
  ;;

  history|log)
    history_flow
  ;;

  tag)
    tag_flow "$2"
  ;;

  clean)
    clean_flow
  ;;

  status|st)
    header "status"
    echo ""
    git status
    echo ""
  ;;

  checkout|co)
    header "checkout"
    info "Trocando para: ${BOLD}${CYAN}$2${RESET}"
    echo ""
    git checkout "$2" && success "Branch ativa: $2"
  ;;

  info)
    info_flow
  ;;

  *)
    echo ""
    echo -e "  ${BOLD}${CYAN}NIT${RESET}  ${DIM}CLI GIT Workflow Simplify${RESET}"
    sep

    label "novo projeto"
    echo -e "  ${GREEN}nit init${RESET}                   iniciar e publicar git"

    label "commits"
    echo -e "  ${GREEN}feat${RESET} ${DIM}|${RESET} ${GREEN}fix${RESET} ${DIM}|${RESET} ${GREEN}docs${RESET} ${DIM}|${RESET} ${GREEN}refactor${RESET} ${DIM}|${RESET} ${GREEN}test${RESET} ${DIM}|${RESET} ${GREEN}chore${RESET} ${DIM}|${RESET} ${GREEN}perf${RESET} ${DIM}|${RESET} ${GREEN}style${RESET} ${DIM}|${RESET} ${GREEN}ci${RESET} ${DIM}|${RESET} ${GREEN}build${RESET}"
    echo -e "  ${DIM}nit feat \"mensagem\"${RESET}        nova feature"
    echo -e "  ${DIM}nit fix TICKET-123 \"msg\"${RESET}  com ticket"
    echo -e "  ${GREEN}nit wip${RESET}                    salvar work in progress"
    echo -e "  ${GREEN}nit amend${RESET}                  editar último commit"
    echo -e "  ${GREEN}nit undo${RESET}                   desfazer último commit"

    label "branches"
    echo -e "  ${GREEN}nit branch${RESET}                 listar"
    echo -e "  ${GREEN}nit branch${RESET} ${DIM}<tipo> <nome>${RESET}   criar  ${DIM}→ ex: nit branch feat auth${RESET}"
    echo -e "  ${GREEN}nit checkout${RESET} ${DIM}<branch>${RESET}      trocar  ${DIM}(alias: co)${RESET}"
    echo -e "  ${GREEN}nit clean${RESET}                  remover branches mescladas"

    label "sincronização"
    echo -e "  ${GREEN}nit push${RESET}                   push da branch atual"
    echo -e "  ${GREEN}nit pull${RESET}                   pull da branch atual"
    echo -e "  ${GREEN}nit sync${RESET}                   pull + push"

    label "utilitários"
    echo -e "  ${GREEN}nit diff${RESET} ${DIM}[--staged|-s]${RESET}     ver alterações"
    echo -e "  ${GREEN}nit stash${RESET} ${DIM}[save|list|pop|drop|clear]${RESET}"
    echo -e "  ${GREEN}nit status${RESET}  ${DIM}(alias: st)${RESET}    git status"
    echo -e "  ${GREEN}nit info${RESET}                   branch + último commit + status"
    echo -e "  ${GREEN}nit history${RESET}  ${DIM}(alias: log)${RESET}  log gráfico"
    echo -e "  ${GREEN}nit tag${RESET} ${DIM}[list|create|delete]${RESET}"

    label "histórico"
    echo -e "  ${GREEN}nit cherry${RESET}                 cherry-pick assistido"
    echo -e "  ${GREEN}nit reset${RESET}                  reset seguro"
    echo -e "  ${GREEN}nit revert${RESET}                 reverter commit"

    sep
    echo ""
  ;;

esac