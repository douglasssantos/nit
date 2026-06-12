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
  echo -en "  ${CYAN}?${RESET} ${BOLD}$1${RESET} ${DIM}›${RESET} " >&2
  read -r value
  echo "$value"
}

confirm() {
  echo -en "  ${YELLOW}?${RESET} ${BOLD}$1${RESET} ${DIM}[y/N]${RESET} " >&2
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
# New Branch (seleção de escopo)
# ========================

new_branch_flow() {
  local name
  name=$(slugify "$*")

  if [[ -z "$name" ]]; then
    abort "Uso: nit new branch <nome>  →  ex: nit new branch adjusted-component"
  fi

  header "new branch"
  info "Nome: ${BOLD}${CYAN}$name${RESET}"
  echo ""
  echo -e "  ${BOLD}Qual o escopo da branch?${RESET}"
  echo ""

  local scopes=(
    feat
    hotfix
    bug
    fix
    enhancement
    improvement
    refactor
    docs
    test
    chore
    release
    style
    perf
    ci
    wip
  )

  local i=1
  for scope in "${scopes[@]}"; do
    printf "  ${CYAN}[%2d]${RESET} %s\n" "$i" "$scope"
    ((i++))
  done
  echo ""

  local choice scope_selected
  choice=$(ask "Escopo")

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#scopes[@]} )); then
    scope_selected="${scopes[$((choice-1))]}"
  else
    abort "Opção inválida."
  fi

  local branch="$scope_selected/$name"
  echo ""
  info "Branch: ${BOLD}${CYAN}$branch${RESET}"
  echo ""
  git checkout -b "$branch" && success "Branch ${BOLD}$branch${RESET} criada e ativa."
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

  local dir remote desc branch
  dir=$(basename "$(pwd)")

  info "Diretório: ${BOLD}${CYAN}$dir${RESET}"
  echo ""

  desc=$(ask "Mensagem do commit inicial ${DIM}(Enter para 'initial commit')${RESET}")
  [[ -z "$desc" ]] && desc="initial commit"

  branch=$(ask "Branch principal ${DIM}(Enter para 'main')${RESET}")
  [[ -z "$branch" ]] && branch="main"

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
# Rename (renomeia branch atual)
# ========================

rename_flow() {
  local old_branch new_branch
  old_branch=$(get_current_branch)
  header "rename"
  info "Branch atual: ${BOLD}${CYAN}$old_branch${RESET}"
  echo ""
  local new_name
  new_name=$(ask "Novo nome")
  [[ -z "$new_name" ]] && abort "Nome não pode ser vazio."
  new_branch=$(slugify "$new_name")
  echo ""
  git branch -m "$old_branch" "$new_branch" && success "Branch renomeada para ${BOLD}$new_branch${RESET}."
  if confirm "Atualizar remote também?"; then
    git push origin --delete "$old_branch" 2>/dev/null || true
    git push origin -u "$new_branch" && success "Remote atualizado."
  fi
}

# ========================
# Delete (deleta branch local)
# ========================

delete_branch_flow() {
  local target="${1:-}"
  header "delete branch"
  if [[ -z "$target" ]]; then
    echo ""
    git branch
    echo ""
    target=$(ask "Branch para deletar")
  fi
  [[ -z "$target" ]] && abort "Nome não pode ser vazio."
  local current
  current=$(get_current_branch)
  [[ "$target" == "$current" ]] && abort "Não é possível deletar a branch ativa."
  echo ""
  confirm "Deletar branch ${BOLD}$target${RESET}?" || exit 0
  if git branch -d "$target"; then
    success "Branch ${BOLD}$target${RESET} deletada."
  else
    warn "Branch não mesclada."
    confirm "Forçar deleção com -D?" && git branch -D "$target" && success "Branch ${BOLD}$target${RESET} deletada (forçado)."
  fi
  echo ""
  if confirm "Remover do remote também?"; then
    git push origin --delete "$target" && success "Branch removida do remote."
  fi
}

# ========================
# Squash (une últimos N commits)
# ========================

squash_flow() {
  header "squash"
  info "Últimos 10 commits:"
  echo ""
  git log --oneline -10
  echo ""
  local n
  n=$(ask "Quantos commits deseja unir?")
  [[ "$n" =~ ^[0-9]+$ ]] || abort "Número inválido."
  (( n >= 2 )) || abort "Precisa ser pelo menos 2."
  local msg
  msg=$(ask "Mensagem do commit final")
  [[ -z "$msg" ]] && abort "Mensagem não pode ser vazia."
  echo ""
  confirm "Unir os últimos ${BOLD}$n${RESET} commits em um?" || exit 0
  git reset --soft "HEAD~$n" && git commit -m "$msg" && success "Squash realizado: ${BOLD}$msg${RESET}."
}

# ========================
# Open (abre repositório no browser)
# ========================

open_flow() {
  header "open"
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null) || abort "Remote 'origin' não encontrado."
  local url
  url=$(echo "$remote_url" \
    | sed 's|git@github.com:|https://github.com/|' \
    | sed 's|git@gitlab.com:|https://gitlab.com/|' \
    | sed 's|\.git$||')
  info "Abrindo: ${DIM}$url${RESET}"
  echo ""
  open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null || abort "Não foi possível abrir o browser."
  success "Browser aberto."
}

# ========================
# PR (cria Pull Request via GitHub CLI)
# ========================

pr_flow() {
  header "pr"
  command -v gh > /dev/null 2>&1 || abort "GitHub CLI (gh) não instalado. Veja: https://cli.github.com"
  local branch
  branch=$(get_current_branch)
  info "Branch: ${BOLD}${CYAN}$branch${RESET}"
  echo ""
  local title body base
  title=$(ask "Título do PR")
  [[ -z "$title" ]] && abort "Título não pode ser vazio."
  body=$(ask "Descrição ${DIM}(opcional)${RESET}")
  base=$(ask "Branch base ${DIM}(Enter para 'main')${RESET}")
  [[ -z "$base" ]] && base="main"
  echo ""
  info "Criando PR: ${BOLD}$title${RESET} → ${CYAN}$base${RESET}"
  echo ""
  gh pr create --title "$title" --body "${body:-}" --base "$base" && success "PR criado com sucesso."
}

# ========================
# Contributors (lista contribuidores)
# ========================

contributors_flow() {
  header "contributors"
  echo ""
  git shortlog -sn --all | head -20
  echo ""
}

# ========================
# Stats (estatísticas do repositório)
# ========================

stats_flow() {
  header "stats"
  echo ""
  local total_commits branches tags contributors first_commit
  total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
  branches=$(git branch -a | wc -l | tr -d ' ')
  tags=$(git tag | wc -l | tr -d ' ')
  contributors=$(git shortlog -sn --all | wc -l | tr -d ' ')
  first_commit=$(git log --reverse --pretty=format:"%ar" | head -1)
  echo -e "  ${BOLD}commits${RESET}         ${CYAN}$total_commits${RESET}"
  echo -e "  ${BOLD}branches${RESET}        ${CYAN}$branches${RESET}"
  echo -e "  ${BOLD}tags${RESET}            ${CYAN}$tags${RESET}"
  echo -e "  ${BOLD}contribuidores${RESET}  ${CYAN}$contributors${RESET}"
  echo -e "  ${BOLD}primeiro commit${RESET} ${DIM}$first_commit${RESET}"
  sep
  echo ""
}

# ========================
# Backup (cria branch de backup)
# ========================

backup_flow() {
  local branch timestamp backup
  branch=$(get_current_branch)
  timestamp=$(date +%Y%m%d-%H%M%S)
  backup="backup/$branch-$timestamp"
  header "backup"
  info "Branch atual: ${BOLD}${CYAN}$branch${RESET}"
  info "Backup:       ${BOLD}${CYAN}$backup${RESET}"
  echo ""
  git checkout -b "$backup" && git checkout "$branch" && success "Backup criado: ${BOLD}$backup${RESET}."
}

# ========================
# Switch (troca branch com listagem interativa)
# ========================

switch_flow() {
  header "switch"
  echo ""
  local branches
  mapfile -t branches < <(git branch | sed 's/^[* ]*//')
  [[ ${#branches[@]} -eq 0 ]] && abort "Nenhuma branch encontrada."
  local current i=1
  current=$(get_current_branch)
  for b in "${branches[@]}"; do
    if [[ "$b" == "$current" ]]; then
      printf "  ${GREEN}[%2d]${RESET} ${BOLD}%s${RESET} ${DIM}← atual${RESET}\n" "$i" "$b"
    else
      printf "  ${CYAN}[%2d]${RESET} %s\n" "$i" "$b"
    fi
    ((i++))
  done
  echo ""
  local choice
  choice=$(ask "Branch")
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#branches[@]} )); then
    local target="${branches[$((choice-1))]}"
    echo ""
    git checkout "$target" && success "Branch ativa: ${BOLD}$target${RESET}."
  else
    abort "Opção inválida."
  fi
}

# ========================
# Version / Release
# ========================

get_current_version() {
  local version=""
  if [[ -f "package.json" ]]; then
    version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' package.json | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  fi
  if [[ -z "$version" ]] && [[ -f "composer.json" ]]; then
    version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' composer.json | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  fi
  if [[ -z "$version" ]] && [[ -f "VERSION" ]]; then
    version=$(cat VERSION | tr -d '[:space:]')
  fi
  if [[ -z "$version" ]] && [[ -f "version.txt" ]]; then
    version=$(cat version.txt | tr -d '[:space:]')
  fi
  if [[ -z "$version" ]] && [[ -f "changelog.md" ]]; then
    version=$(grep -o '\[[0-9][^]]*\]' changelog.md | head -1 | tr -d '[]')
  fi
  echo "$version"
}

increment_semver() {
  local version="$1"
  local bump="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}
  case "$bump" in
    major) ((major++)); minor=0; patch=0 ;;
    minor) ((minor++)); patch=0 ;;
    patch) ((patch++)) ;;
  esac
  echo "$major.$minor.$patch"
}

update_version_in_file() {
  local file="$1"
  local old_ver="$2"
  local new_ver="$3"
  case "$file" in
    package.json|package-lock.json|composer.json|app.json|manifest.json)
      sed -i.bak "s/\"version\":[[:space:]]*\"${old_ver}\"/\"version\": \"${new_ver}\"/" "$file" && rm -f "${file}.bak"
      ;;
    pom.xml)
      sed -i.bak "s|<version>${old_ver}</version>|<version>${new_ver}</version>|" "$file" && rm -f "${file}.bak"
      ;;
    build.gradle|gradle.properties|pyproject.toml|setup.py|Cargo.toml)
      sed -i.bak "s/${old_ver}/${new_ver}/" "$file" && rm -f "${file}.bak"
      ;;
    VERSION|version.txt)
      echo "$new_ver" > "$file"
      ;;
    .env)
      sed -i.bak "s/VERSION=${old_ver}/VERSION=${new_ver}/" "$file" && rm -f "${file}.bak"
      ;;
    config/version.php)
      sed -i.bak "s/'${old_ver}'/'${new_ver}'/" "$file" && rm -f "${file}.bak"
      ;;
  esac
}

update_changelog() {
  local new_ver="$1"
  local change_type="$2"
  shift 2
  local notes=("$@")
  local today
  today=$(date +%Y-%m-%d)

  if [[ ! -f "changelog.md" ]]; then
    {
      echo "# Changelog"
      echo ""
      echo "Todas as alterações relevantes deste projeto serão documentadas neste arquivo."
      echo ""
    } > changelog.md
  fi

  local entry
  entry="## [${new_ver}] - ${today}\n\n### Tipo\n${change_type}\n\n### Alterações\n"
  for note in "${notes[@]}"; do
    entry+="- ${note}\n"
  done
  entry+="\n"

  local insert_line
  insert_line=$(grep -n "^## \[" changelog.md | head -1 | cut -d: -f1)

  local tmp
  tmp=$(mktemp)

  if [[ -n "$insert_line" ]]; then
    head -n $((insert_line - 1)) changelog.md > "$tmp"
    printf '%b' "$entry" >> "$tmp"
    tail -n +"${insert_line}" changelog.md >> "$tmp"
  else
    cat changelog.md > "$tmp"
    printf '\n%b' "$entry" >> "$tmp"
  fi

  mv "$tmp" changelog.md
}

version_flow() {
  header "release"

  # Etapa 1 — Versão atual
  local current_version
  current_version=$(get_current_version)

  if [[ -z "$current_version" ]]; then
    warn "Nenhuma versão encontrada nos arquivos do projeto. Usando 0.0.0 como base."
    current_version="0.0.0"
  else
    info "Versão atual encontrada: ${BOLD}${CYAN}$current_version${RESET}"
  fi
  echo ""

  # Etapa 3 — Tipo da alteração (antes para cálculo automático)
  echo -e "  ${BOLD}Qual o tipo da alteração?${RESET}"
  echo ""
  local types=(bugfix hotfix enhancement feature project new-version change-breaking)
  local i=1
  for t in "${types[@]}"; do
    printf "  ${CYAN}[%d]${RESET} %s\n" "$i" "$t"
    ((i++))
  done
  echo ""

  local type_choice change_type bump_type
  type_choice=$(ask "Tipo")

  if [[ "$type_choice" =~ ^[0-9]+$ ]] && (( type_choice >= 1 && type_choice <= ${#types[@]} )); then
    change_type="${types[$((type_choice-1))]}"
  else
    abort "Opção inválida."
  fi

  case "$change_type" in
    bugfix|hotfix)              bump_type="patch" ;;
    enhancement|feature)        bump_type="minor" ;;
    project|new-version|change-breaking) bump_type="major" ;;
  esac

  # Etapa 2 — Versão manual ou automática
  echo ""
  echo -e "  ${BOLD}Deseja informar manualmente a nova versão?${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET} Sim"
  echo -e "  ${CYAN}[2]${RESET} Não ${DIM}(calculada automaticamente)${RESET}"
  echo ""
  local manual_choice
  manual_choice=$(ask "Opção")

  local new_version
  if [[ "$manual_choice" == "1" ]]; then
    echo ""
    new_version=$(ask "Informe a versão")
    [[ -z "$new_version" ]] && abort "Versão não pode ser vazia."
  else
    if [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      new_version=$(increment_semver "$current_version" "$bump_type")
    else
      new_version=$(increment_semver "0.0.0" "$bump_type")
    fi
  fi

  echo ""
  info "Versão Atual:  ${BOLD}$current_version${RESET}"
  info "Tipo:          ${BOLD}$change_type${RESET}"
  info "Nova Versão:   ${BOLD}${GREEN}$new_version${RESET}"
  echo ""

  # Verificar se tag já existe
  if git tag -l "v$new_version" | grep -q .; then
    abort "Tag v$new_version já existe. Escolha outra versão."
  fi

  # Etapa 4 — Release Notes
  sep
  label "Release Notes"
  info "Informe as alterações desta versão ${DIM}(linha vazia para finalizar)${RESET}:"
  echo ""

  local notes=()
  while true; do
    local note
    note=$(ask "item")
    [[ -z "$note" ]] && break
    notes+=("$note")
  done
  [[ ${#notes[@]} -eq 0 ]] && abort "Ao menos uma nota de release é obrigatória."

  # Etapa 5 — Atualizar arquivos de versão?
  echo ""
  sep
  echo ""
  echo -e "  ${BOLD}Deseja atualizar automaticamente os arquivos de versão?${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET} Sim"
  echo -e "  ${CYAN}[2]${RESET} Não"
  echo ""
  local update_choice
  update_choice=$(ask "Opção")

  local all_candidates=(
    "package.json" "package-lock.json" "composer.json" "composer.lock"
    "pom.xml" "build.gradle" "gradle.properties" "pyproject.toml"
    "setup.py" "Cargo.toml" "VERSION" "version.txt" ".env"
    "config/version.php" "app.json" "manifest.json"
  )
  local version_files=()
  for f in "${all_candidates[@]}"; do
    [[ -f "$f" ]] && version_files+=("$f")
  done

  # Etapa 6 — Release no Git?
  echo ""
  echo -e "  ${BOLD}Deseja gerar uma Release no Git?${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET} Sim"
  echo -e "  ${CYAN}[2]${RESET} Não"
  echo ""
  local git_release_choice
  git_release_choice=$(ask "Opção")
  local git_release=false
  [[ "$git_release_choice" == "1" ]] && git_release=true

  # Etapa 7 — Branch alvo
  local current_branch target_branch
  current_branch=$(get_current_branch)
  echo ""
  info "Branch atual: ${BOLD}${CYAN}$current_branch${RESET}"
  echo ""
  local branch_input
  branch_input=$(ask "Branch alvo da release ${DIM}(Enter para usar a atual)${RESET}")
  [[ -z "$branch_input" ]] && target_branch="$current_branch" || target_branch="$branch_input"

  echo ""
  info "Branch selecionada: ${BOLD}${CYAN}$target_branch${RESET}"
  echo ""
  confirm "Deseja continuar?" || { echo ""; warn "Operação cancelada."; echo ""; exit 0; }

  # Etapa 9 — Resumo
  echo ""
  sep
  label "Resumo da Release"
  sep
  echo ""
  echo -e "  ${BOLD}Versão Atual:${RESET}      $current_version"
  echo -e "  ${BOLD}Nova Versão:${RESET}       ${GREEN}$new_version${RESET}"
  echo -e "  ${BOLD}Tipo:${RESET}              $change_type"
  echo -e "  ${BOLD}Branch:${RESET}            $target_branch"
  echo -e "  ${BOLD}Tag:${RESET}               ${CYAN}v$new_version${RESET}"
  echo -e "  ${BOLD}Release Git:${RESET}       $( [[ "$git_release" == true ]] && echo 'Sim' || echo 'Não' )"
  echo ""
  echo -e "  ${BOLD}Arquivos a atualizar:${RESET}"
  if [[ "$update_choice" == "1" ]] && [[ ${#version_files[@]} -gt 0 ]]; then
    for f in "${version_files[@]}"; do
      echo -e "  ${DIM}·${RESET} $f"
    done
  fi
  echo -e "  ${DIM}·${RESET} changelog.md"
  echo ""
  echo -e "  ${BOLD}Release Notes:${RESET}"
  for note in "${notes[@]}"; do
    echo -e "  ${DIM}·${RESET} $note"
  done
  echo ""
  sep
  echo ""

  # Etapa 10 — Confirmação final
  confirm "Deseja prosseguir?" || {
    echo ""
    warn "Processo cancelado. Nenhuma alteração foi realizada."
    echo ""
    exit 0
  }

  echo ""
  sep

  # Criar backups
  local backed_up=()
  [[ -f "changelog.md" ]] && { cp changelog.md changelog.md.nit.bak; backed_up+=("changelog.md"); }
  if [[ "$update_choice" == "1" ]]; then
    for f in "${version_files[@]}"; do
      cp "$f" "$f.nit.bak"
      backed_up+=("$f")
    done
  fi

  # Rollback em caso de erro
  rollback_version() {
    error "Erro detectado. Revertendo alterações..."
    for f in "${backed_up[@]}"; do
      if [[ -f "$f.nit.bak" ]]; then
        mv "$f.nit.bak" "$f"
        warn "Restaurado: $f"
      fi
    done
    git tag -d "v$new_version" 2>/dev/null || true
    if git log --oneline -1 2>/dev/null | grep -q "chore(release): v$new_version"; then
      git reset --soft HEAD~1
      warn "Commit de release desfeito."
    fi
    echo ""
    error "Processo cancelado. Todas as alterações foram revertidas."
    echo ""
  }

  # Atualizar changelog
  info "Atualizando changelog.md..."
  update_changelog "$new_version" "$change_type" "${notes[@]}" || { rollback_version; exit 1; }
  success "changelog.md atualizado."

  # Atualizar arquivos de versão
  if [[ "$update_choice" == "1" ]] && [[ ${#version_files[@]} -gt 0 ]]; then
    info "Atualizando arquivos de versão..."
    for f in "${version_files[@]}"; do
      update_version_in_file "$f" "$current_version" "$new_version" && success "$f" || { rollback_version; exit 1; }
    done
  fi

  # Operações Git
  if [[ "$git_release" == true ]]; then
    info "Adicionando arquivos..."
    git add . || { rollback_version; exit 1; }
    info "Criando commit de release..."
    git commit -m "chore(release): v$new_version" || { rollback_version; exit 1; }
    info "Criando tag v$new_version..."
    git tag -a "v$new_version" -m "Release v$new_version" || { rollback_version; exit 1; }
    info "Enviando branch ${target_branch}..."
    git push origin "$target_branch" || { rollback_version; exit 1; }
    info "Enviando tag v$new_version..."
    git push origin "v$new_version" || { rollback_version; exit 1; }

    # GitHub / GitLab CLI
    if command -v gh > /dev/null 2>&1; then
      echo ""
      if confirm "Criar GitHub Release via gh CLI?"; then
        local release_body=""
        for note in "${notes[@]}"; do
          release_body+="- $note"$'\n'
        done
        gh release create "v$new_version" \
          --title "Release v$new_version" \
          --notes "$release_body" \
          --target "$target_branch" \
          && success "GitHub Release criada."
      fi
    elif command -v glab > /dev/null 2>&1; then
      echo ""
      if confirm "Criar GitLab Release via glab CLI?"; then
        glab release create "v$new_version" && success "GitLab Release criada."
      fi
    fi
  else
    echo ""
    if confirm "Commitar os arquivos atualizados?"; then
      git add .
      git commit -m "chore(release): v$new_version" && success "Commit criado."
      git tag -a "v$new_version" -m "Release v$new_version" && success "Tag v$new_version criada."
    fi
  fi

  # Limpar backups
  for f in "${backed_up[@]}"; do
    rm -f "$f.nit.bak"
  done

  echo ""
  sep
  success "Release ${BOLD}v$new_version${RESET} concluída com sucesso!"
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

  new)
    if [[ "$2" == "branch" ]]; then
      shift 2
      new_branch_flow "$@"
    else
      error "Subcomando desconhecido: 'new $2'"
      echo -e "  ${DIM}Uso: nit new branch <nome>${RESET}\n"
      exit 1
    fi
  ;;

  nb)
    shift
    new_branch_flow "$@"
  ;;

  rename)
    rename_flow
  ;;

  delete|del)
    delete_branch_flow "$2"
  ;;

  squash)
    squash_flow
  ;;

  open)
    open_flow
  ;;

  pr)
    pr_flow
  ;;

  contributors|contrib)
    contributors_flow
  ;;

  stats)
    stats_flow
  ;;

  backup)
    backup_flow
  ;;

  switch|sw)
    switch_flow
  ;;

  version|release)
    version_flow
  ;;

  *)
    echo ""
    echo -e "  ${BOLD}${CYAN}NIT${RESET}  ${DIM}CLI GIT Workflow Simplify${RESET}"
    sep

    label "novo projeto"
    echo -e "  ${GREEN}nit init${RESET}                   iniciar e publicar Repositório"

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
    echo -e "  ${GREEN}nit new branch${RESET} ${DIM}<nome>${RESET}      criar com seleção de escopo  ${DIM}(alias: nb)${RESET}"
    echo -e "  ${GREEN}nit rename${RESET}                 renomear branch atual"
    echo -e "  ${GREEN}nit delete${RESET} ${DIM}<branch>${RESET}        deletar branch  ${DIM}(alias: del)${RESET}"
    echo -e "  ${GREEN}nit switch${RESET}                 trocar branch interativo  ${DIM}(alias: sw)${RESET}"
    echo -e "  ${GREEN}nit checkout${RESET} ${DIM}<branch>${RESET}      trocar  ${DIM}(alias: co)${RESET}"
    echo -e "  ${GREEN}nit backup${RESET}                 criar branch de backup"
    echo -e "  ${GREEN}nit clean${RESET}                  remover branches mescladas"

    label "sincronização"
    echo -e "  ${GREEN}nit push${RESET}                   push da branch atual"
    echo -e "  ${GREEN}nit pull${RESET}                   pull da branch atual"
    echo -e "  ${GREEN}nit sync${RESET}                   pull + push"
    echo -e "  ${GREEN}nit open${RESET}                   abrir repositório no browser"
    echo -e "  ${GREEN}nit pr${RESET}                     criar Pull Request ${DIM}(requer gh CLI)${RESET}"

    label "utilitários"
    echo -e "  ${GREEN}nit diff${RESET} ${DIM}[--staged|-s]${RESET}     ver alterações"
    echo -e "  ${GREEN}nit stash${RESET} ${DIM}[save|list|pop|drop|clear]${RESET}"
    echo -e "  ${GREEN}nit squash${RESET}                 unir últimos N commits"
    echo -e "  ${GREEN}nit status${RESET}  ${DIM}(alias: st)${RESET}    git status"
    echo -e "  ${GREEN}nit info${RESET}                   branch + último commit + status"
    echo -e "  ${GREEN}nit stats${RESET}                  estatísticas do repositório"
    echo -e "  ${GREEN}nit contributors${RESET}           lista de contribuidores  ${DIM}(alias: contrib)${RESET}"
    echo -e "  ${GREEN}nit history${RESET}  ${DIM}(alias: log)${RESET}  log gráfico"
    echo -e "  ${GREEN}nit tag${RESET} ${DIM}[list|create|delete]${RESET}"

    label "versionamento"
    echo -e "  ${GREEN}nit release${RESET}                gerenciar versão e publicar release  ${DIM}(alias: version)${RESET}"

    label "histórico"
    echo -e "  ${GREEN}nit cherry${RESET}                 cherry-pick assistido"
    echo -e "  ${GREEN}nit reset${RESET}                  reset seguro"
    echo -e "  ${GREEN}nit revert${RESET}                 reverter commit"

    sep
    echo ""
  ;;

esac