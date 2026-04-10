# nit

CLI bash minimalista para simplificar o workflow com git — commits semânticos, branches tipadas, stash, tags e mais, tudo direto do terminal.

---

## Instalação

### Automática (recomendado)

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

## Operações avançadas

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

# Criar branch para nova feature
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

# Sincronizar com remote
nit sync
```

---

## Referência rápida

| Comando | Descrição |
|---|---|
| `nit init` | Inicializar e publicar Repositório |
| `nit feat/fix/...` | Commit semântico |
| `nit wip` | Commit rápido de WIP |
| `nit amend` | Editar último commit |
| `nit undo` | Desfazer último commit |
| `nit branch` | Listar branches |
| `nit branch <tipo> <nome>` | Criar branch tipada |
| `nit checkout <branch>` / `nit co` | Trocar de branch |
| `nit clean` | Remover branches mescladas |
| `nit push` | Push da branch atual |
| `nit pull` | Pull da branch atual |
| `nit sync` | Pull + push |
| `nit diff [--staged\|-s]` | Ver alterações |
| `nit stash [save\|list\|pop\|drop\|clear]` | Gerenciar stash |
| `nit status` / `nit st` | Git status |
| `nit info` | Painel da branch atual |
| `nit history` / `nit log` | Log gráfico |
| `nit tag [list\|create\|delete]` | Gerenciar tags |
| `nit cherry` | Cherry-pick assistido |
| `nit reset` | Reset seguro |
| `nit revert` | Reverter commit |

---

## Requisitos

- bash 4+
- git

