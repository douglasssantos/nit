# nit

CLI bash minimalista para simplificar o workflow com git — commits semânticos, branches tipadas, stash, tags e mais, tudo direto do terminal.

---

## Instalação

### Automática - Utilizando Curl (recomendado)

```bash
curl -L https://github.com/douglasssantos/nit/archive/refs/heads/main.zip -o nit.zip && unzip nit.zip && cd nit-main && sudo bash install.sh
```

### Automática - Clonando o Repositório

```bash
bash install.sh
```

O script verifica dependências, copia o binário para `/usr/local/bin/nit` e valida o PATH. Solicita `sudo` automaticamente se necessário.

### Manual

```bash
cp .nit /usr/local/bin/nit
chmod +x /usr/local/bin/nit
```

Ou com symlink (útil para desenvolvimento):

```bash
ln -s "$(pwd)/.nit" /usr/local/bin/nit
```

---

## Novo projeto

Inicializa e publica um projeto no GitHub em um único comando:

```bash
nit init
```

Etapas executadas automaticamente:

```
? Mensagem do commit inicial  › initial commit
? Branch principal            › main
? URL do repositório remoto   › git@github.com:user/projeto.git

→ git init
→ git add .
→ git commit -m "initial commit"
→ git branch -M main
→ git remote add origin <url>
→ git push -u origin main
```

- Se o diretório já for um repositório git, pergunta se deseja continuar
- Se já existir um remote `origin`, atualiza a URL automaticamente
- Branch padrão: `main` (pressione Enter para aceitar)

---

## Commits semânticos

O nit segue o padrão [Conventional Commits](https://www.conventionalcommits.org/).

### Formas de uso

**Modo interativo** — solicita escopo e descrição:
```bash
nit feat
# ? Escopo      › auth
# ? Descrição   › adicionar login com OAuth
# → feat(auth): adicionar login com OAuth
```

**Mensagem direta:**
```bash
nit fix "corrigir erro de validação"
# → fix: corrigir erro de validação
```

**Com issue/ticket:**
```bash
nit feat ABC-123 "implementar dashboard"
# → feat(auth): ABC-123 implementar dashboard
# (escopo extraído automaticamente do nome da branch)
```

Após o commit, o nit pergunta se deseja fazer push.

### Tipos disponíveis

| Comando        | Uso                                      |
|----------------|------------------------------------------|
| `nit feat`     | Nova funcionalidade                      |
| `nit fix`      | Correção de bug                          |
| `nit docs`     | Documentação                             |
| `nit refactor` | Refatoração sem mudança de comportamento |
| `nit test`     | Adição ou correção de testes             |
| `nit chore`    | Tarefas de manutenção                    |
| `nit perf`     | Melhoria de performance                  |
| `nit style`    | Formatação, espaçamento, etc.            |
| `nit ci`       | Configuração de CI/CD                    |
| `nit build`    | Alterações no sistema de build           |
| `nit temp`     | Commit temporário                        |
| `nit adjust`   | Pequenos ajustes                         |

### WIP

Salva rapidamente o trabalho em progresso sem precisar escrever mensagem:

```bash
nit wip
# → wip: trabalho em progresso
```

### Amend

Edita o último commit (exibe a mensagem atual antes de perguntar):

```bash
nit amend
# [1] Alterar mensagem
# [2] Adicionar arquivos staged (mantém mensagem)
```

### Undo

Desfaz o último commit (exibe a mensagem atual antes de perguntar):

```bash
nit undo
# [1] soft  — mantém alterações staged
# [2] mixed — mantém alterações unstaged
# [3] hard  — descarta tudo permanentemente
```

---

## Branches

### Criar branch tipada

```bash
nit branch feat login-com-google
# → cria e ativa: feat/login-com-google

nit branch fix corrigir-timeout
# → cria e ativa: fix/corrigir-timeout
```

O nome é automaticamente convertido para slug (lowercase, sem espaços).

### Criar branch com seleção de escopo

```bash
nit new branch adjusted-component
nit nb adjusted-component   # alias
```

Exibe uma lista numerada de escopos para escolher interativamente:

```
  Qual o escopo da branch?

   [ 1] feat
   [ 2] hotfix
   [ 3] bug
   [ 4] fix
   [ 5] enhancement
   [ 6] improvement
   [ 7] refactor
   [ 8] docs
   [ 9] test
   [10] chore
   [11] release
   [12] style
   [13] perf
   [14] ci
   [15] wip

  ? Escopo › 6
  → git checkout -b improvement/adjusted-component
```

### Listar branches

```bash
nit branch
```

### Trocar de branch (interativo)

```bash
nit switch   # lista branches numeradas para seleção
nit sw       # alias
```

### Trocar de branch (direto)

```bash
nit checkout fix/corrigir-timeout
nit co fix/corrigir-timeout   # alias
```

### Renomear branch atual

```bash
nit rename
# ? Novo nome › nova-feature
# → renomeia localmente e oferece atualizar o remote
```

### Deletar branch

```bash
nit delete fix/corrigir-timeout
nit del fix/corrigir-timeout   # alias
# → confirmação antes de deletar; oferece remoção do remote
# → se a branch não estiver mesclada, pergunta se deseja forçar com -D
```

### Criar branch de backup

```bash
nit backup
# → cria: backup/<branch-atual>-<timestamp>
# → volta automaticamente para a branch original
```

### Remover branches mescladas

```bash
nit clean
# Lista branches já mescladas na branch principal e confirma antes de deletar
# Branches main, master e develop são preservadas automaticamente
```

---

## Sincronização

```bash
nit push    # push da branch atual para origin
nit pull    # pull da branch atual
nit sync    # pull + push (sincronização completa)
```

### Abrir repositório no browser

```bash
nit open
# Detecta automaticamente GitHub ou GitLab (SSH ou HTTPS)
```

### Criar Pull Request

```bash
nit pr
# Requer GitHub CLI (gh) instalado: https://cli.github.com
# ? Título do PR  ›
# ? Descrição     ›
# ? Branch base   › main
```

---

## Diff

```bash
nit diff            # alterações não adicionadas (unstaged)
nit diff --staged   # alterações prontas para commit (staged)
nit diff -s         # alias para --staged
```

---

## Stash

```bash
nit stash           # salva stash (solicita descrição opcional)
nit stash save      # idem
nit stash list      # lista todos os stashes
nit stash ls        # alias para list
nit stash pop       # restaura stash (escolha interativa do índice)
nit stash drop      # remove um stash específico
nit stash clear     # remove todos os stashes (pede confirmação)
```

---

## Tags

```bash
nit tag             # lista as últimas 20 tags ordenadas por versão
nit tag list        # idem
nit tag create      # cria tag anotada ou leve, com opção de push
nit tag delete      # remove tag local e opcionalmente do remote
```

---

## Histórico

```bash
nit history   # log gráfico com todas as branches
nit log       # alias
```

---

## Utilitários

```bash
nit status    # git status completo
nit st        # alias para status

nit info      # painel: branch atual + hash + mensagem + autor + status colorido

nit stats     # estatísticas: commits, branches, tags, contribuidores, data do primeiro commit

nit squash    # une os últimos N commits em um único
# Exibe os últimos 10 commits, solicita quantidade e mensagem final

nit contributors   # lista contribuidores ordenados por número de commits
nit contrib        # alias
```

O `nit info` exibe o status dos arquivos com cores por tipo:

| Cor      | Significado               |
|----------|---------------------------|
| Amarelo  | Modificado (staged)       |
| Azul     | Modificado (unstaged)     |
| Verde    | Adicionado                |
| Vermelho | Deletado                  |
| Cinza    | Não rastreado (`??`)      |

---

## Versionamento e Releases

O nit possui um sistema completo de gerenciamento de versões com suporte a três estratégias de versionamento.

### Estratégias suportadas

| Estratégia | Formato             | Exemplo          |
|------------|---------------------|------------------|
| SemVer     | `MAJOR.MINOR.PATCH` | `1.5.0`          |
| CalVer     | `YY.MM`             | `26.06`          |
| Release    | `Release YYYY.N`    | `Release 2026.2` |

A estratégia é detectada automaticamente com base na versão atual do projeto.

### Wizard completo de release

```bash
nit release
nit version   # alias
```

Fluxo guiado com 10 etapas:

1. Detecta a versão atual nos arquivos do projeto (`package.json`, `composer.json`, `VERSION`, etc.)
2. Identifica e permite trocar a estratégia de versionamento
3. Solicita o tipo da alteração para calcular a nova versão automaticamente
4. Permite informar a versão manualmente ou calculá-la com base no tipo
5. Coleta release notes (múltiplos itens, linha vazia para finalizar)
6. Atualiza automaticamente todos os arquivos de versão encontrados
7. Pergunta se deseja gerar uma release no Git
8. Permite definir a branch alvo
9. Exibe um resumo completo antes de qualquer alteração
10. Confirma e executa — ou cancela com rollback completo

**Tipos de alteração e incremento automático:**

| Tipo             | Incremento |
|------------------|------------|
| `bugfix`         | PATCH      |
| `hotfix`         | PATCH      |
| `enhancement`    | MINOR      |
| `feature`        | MINOR      |
| `project`        | MAJOR      |
| `new-version`    | MAJOR      |
| `change-breaking`| MAJOR      |

**Arquivos atualizados automaticamente** (quando existirem):
`package.json`, `package-lock.json`, `composer.json`, `composer.lock`, `pom.xml`, `build.gradle`, `gradle.properties`, `pyproject.toml`, `setup.py`, `Cargo.toml`, `VERSION`, `version.txt`, `.env`, `config/version.php`, `app.json`, `manifest.json`, `changelog.md`

**Execução ao confirmar:**
```bash
git add .
git commit -m "chore(release): v1.5.0"
git tag -a v1.5.0 -m "Release 1.5.0"
git push origin <branch>
git push origin v1.5.0
# + gh release create (se gh CLI disponível)
```

**Rollback automático:** em caso de erro ou cancelamento, todos os arquivos alterados são restaurados e commit/tag são removidos.

---

### Exibir versão atual

```bash
nit version current
```

Exibe a versão detectada nos arquivos do projeto e a estratégia identificada (semver, calver ou release), sem abrir o wizard.

---

### Histórico de versões

```bash
nit version history
```

Lista as tags de versão existentes com suas datas e as últimas entradas do `changelog.md`.

---

### Bump rápido

```bash
nit version bump patch
nit version bump minor
nit version bump major
nit version bump         # seleção interativa
```

Incrementa a versão diretamente sem passar pelo wizard completo:

- Atualiza todos os arquivos de versão encontrados
- Adiciona entrada no `changelog.md`
- Cria commit `chore(release): vX.Y.Z` e tag
- Pergunta se deseja fazer push da branch e da tag

---

## Changelog

```bash
nit changelog            # exibe o conteúdo completo
nit changelog show       # idem
nit changelog versions   # lista somente as entradas de versão
nit changelog search     # busca por termo no changelog
nit changelog last       # exibe apenas a entrada mais recente
```

Se o `changelog.md` não existir, `nit changelog` oferece criar o arquivo automaticamente.

---

### Cherry-pick assistido

```bash
nit cherry
# Exibe os últimos 15 commits e solicita o hash para aplicar
```

### Reset seguro

```bash
nit reset
# [1] soft  — mantém alterações staged
# [2] mixed — mantém alterações unstaged
# [3] hard  — descarta tudo permanentemente (pede confirmação)
```

### Revert

```bash
nit revert
# Exibe os últimos 15 commits e solicita o hash para reverter
# Cria um novo commit que desfaz as mudanças (não altera o histórico)
```

---

## Fluxo de trabalho típico

```bash
# Novo projeto do zero
nit init

# Criar branch com seleção interativa de escopo
nit new branch pagamento-pix
# ou diretamente:
nit branch feat pagamento-pix

# Desenvolver...

# Ver o que mudou
nit diff
nit info

# Salvar trabalho parcial sem commitar
nit stash

# Commitar
nit feat "adicionar integração com API Pix"

# Editar o commit se necessário
nit amend

# Unir commits antes de publicar
nit squash

# Sincronizar com remote
nit sync

# Abrir repositório para revisar
nit open

# Criar PR
nit pr
```

---

## Referência rápida

| Comando | Alias | Descrição |
|---|---|---|
| `nit init` | — | Inicializar e publicar repositório |
| `nit feat/fix/...` | — | Commit semântico |
| `nit wip` | — | Commit rápido de WIP |
| `nit amend` | — | Editar último commit |
| `nit undo` | — | Desfazer último commit |
| `nit squash` | — | Unir últimos N commits |
| `nit branch` | — | Listar branches |
| `nit branch <tipo> <nome>` | — | Criar branch tipada |
| `nit new branch <nome>` | `nb` | Criar branch com seleção de escopo |
| `nit switch` | `sw` | Trocar branch interativo |
| `nit checkout <branch>` | `co` | Trocar de branch (direto) |
| `nit rename` | — | Renomear branch atual |
| `nit delete <branch>` | `del` | Deletar branch local |
| `nit backup` | — | Criar branch de backup |
| `nit clean` | — | Remover branches mescladas |
| `nit push` | — | Push da branch atual |
| `nit pull` | — | Pull da branch atual |
| `nit sync` | — | Pull + push |
| `nit open` | — | Abrir repositório no browser |
| `nit pr` | — | Criar Pull Request (requer `gh`) |
| `nit diff [--staged\|-s]` | — | Ver alterações |
| `nit stash [save\|list\|pop\|drop\|clear]` | — | Gerenciar stash |
| `nit status` | `st` | Git status |
| `nit info` | — | Painel da branch atual |
| `nit stats` | — | Estatísticas do repositório |
| `nit contributors` | `contrib` | Lista de contribuidores |
| `nit history` | `log` | Log gráfico |
| `nit tag [list\|create\|delete]` | — | Gerenciar tags |
| `nit cherry` | — | Cherry-pick assistido |
| `nit reset` | — | Reset seguro |
| `nit revert` | — | Reverter commit |
| `nit release` | `version` | Wizard completo de release |
| `nit version current` | — | Exibir versão atual do projeto |
| `nit version history` | — | Histórico de versões (tags + changelog) |
| `nit version bump [patch\|minor\|major]` | — | Bump rápido sem wizard |
| `nit changelog [show\|versions\|search\|last]` | — | Visualizar e navegar pelo changelog |

---

## Requisitos

- bash 4+
- git
- [gh CLI](https://cli.github.com) *(opcional, necessário para `nit pr`)*

