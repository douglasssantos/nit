# nit

CLI bash minimalista para simplificar o workflow com git — commits semânticos, branches tipadas, stash, tags e mais, tudo direto do terminal.

## Instalação

### Automática (recomendado)

```bash
bash install.sh
```

O script verifica dependências, copia o binário para `/usr/local/bin/nit` e valida o PATH. Solicita `sudo` automaticamente se necessário.

### Manual

```bash
# Copie o script para um local no seu PATH
cp .nit /usr/local/bin/nit
chmod +x /usr/local/bin/nit
```

Ou com symlink (útil para desenvolvimento):

```bash
ln -s "$(pwd)/.nit" /usr/local/bin/nit
```

---

## Commits semânticos

O nit segue o padrão [Conventional Commits](https://www.conventionalcommits.org/).

### Formas de uso

**Modo interativo** — solicita escopo e descrição:
```bash
nit feat
# Escopo: auth
# Descrição: adicionar login com OAuth
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
# (escopo extraído automaticamente da branch atual)
```

### Tipos disponíveis

| Comando       | Uso                          |
|---------------|------------------------------|
| `nit feat`    | Nova funcionalidade           |
| `nit fix`     | Correção de bug               |
| `nit docs`    | Documentação                  |
| `nit refactor`| Refatoração sem mudança de comportamento |
| `nit test`    | Adição ou correção de testes  |
| `nit chore`   | Tarefas de manutenção         |
| `nit perf`    | Melhoria de performance       |
| `nit style`   | Formatação, espaçamento, etc. |
| `nit ci`      | Configuração de CI/CD         |
| `nit build`   | Alterações no sistema de build|
| `nit temp`    | Commit temporário             |
| `nit adjust`  | Pequenos ajustes              |

Após o commit, o nit pergunta se deseja fazer push.

### WIP

Salva rapidamente o trabalho em progresso sem precisar escrever mensagem:

```bash
nit wip
# → wip: trabalho em progresso
```

### Amend

Edita o último commit:

```bash
nit amend
# 1) Alterar mensagem
# 2) Adicionar arquivos ao último commit (sem alterar msg)
```

### Undo

Desfaz o último commit com escolha do modo:

```bash
nit undo
# 1) soft  — mantém alterações staged
# 2) mixed — mantém alterações unstaged
# 3) hard  — descarta tudo
```

---

## Branches

### Criar branch tipada

```bash
nit branch feat login-com-google
# → cria: feat/login-com-google

nit branch fix corrigir-timeout
# → cria: fix/corrigir-timeout
```

O nome é automaticamente convertido para slug (lowercase, sem espaços).

### Listar branches

```bash
nit branch
```

### Trocar de branch

```bash
nit checkout fix/corrigir-timeout
nit co fix/corrigir-timeout   # alias
```

### Remover branches mescladas

```bash
nit clean
# Lista branches já mescladas e confirma antes de deletar
```

---

## Sincronização

```bash
nit push    # push da branch atual para origin
nit pull    # pull da branch atual
nit sync    # pull + push (sincronização completa)
```

---

## Diff

```bash
nit diff            # alterações não adicionadas (unstaged)
nit diff --staged   # alterações já adicionadas (staged)
nit diff -s         # alias para --staged
```

---

## Stash

```bash
nit stash           # salva stash (modo interativo com descrição opcional)
nit stash save      # idem
nit stash list      # lista todos os stashes
nit stash ls        # alias para list
nit stash pop       # restaura stash (escolha interativa do índice)
nit stash drop      # remove um stash específico
nit stash clear     # remove todos os stashes
```

---

## Tags

```bash
nit tag             # lista tags (ordenadas por versão)
nit tag list        # idem
nit tag create      # cria tag (anotada ou leve) com opção de push
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
nit status    # git status
nit st        # alias para status

nit info      # branch atual + último commit + status resumido
```

---

## Operações avançadas

### Cherry-pick assistido

```bash
nit cherry
# Exibe os últimos 15 commits e solicita o hash
```

### Reset seguro

```bash
nit reset
# Escolha entre soft / mixed / hard com confirmação para hard
```

### Revert

```bash
nit revert
# Exibe os últimos 15 commits e solicita o hash para reverter
```

---

## Fluxo de trabalho típico

```bash
# 1. Criar branch para nova feature
nit branch feat pagamento-pix

# 2. Desenvolver...

# 3. Commitar
nit feat "adicionar integração com API Pix"

# 4. Salvar trabalho parcial
nit wip

# 5. Verificar o que mudou
nit diff
nit info

# 6. Sincronizar com remote
nit sync
```

---

## Requisitos

- bash 4+
- git
