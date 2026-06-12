# Gerenciador de Versionamento e Releases

## Objetivo

Implementar uma funcionalidade completa de gerenciamento de versões do projeto, seguindo as melhores práticas de controle de versão, geração de changelog, atualização automática de arquivos de versão e criação de releases no Git.

A funcionalidade deve funcionar como um assistente guiado, realizando perguntas ao usuário antes de executar qualquer alteração.

---

# Convenções de Versionamento Suportadas

## 1. Semantic Versioning (SemVer)

Padrão:

MAJOR.MINOR.PATCH

Referência:
https://semver.org/lang/pt-BR/

### Regras

* MAJOR:
  Alterações incompatíveis com versões anteriores.
  Exemplo:
  1.0.0 → 2.0.0

* MINOR:
  Novas funcionalidades compatíveis.
  Exemplo:
  1.2.0 → 1.3.0

* PATCH:
  Correções de bugs sem impacto de compatibilidade.
  Exemplo:
  1.2.3 → 1.2.4

---

## 2. Calendar Versioning (CalVer)

Formato:

YY.MM

Exemplo:

24.05
26.06

Referência:
https://www.autodesk.com/br/support/technical/article/caas/sfdcarticles/sfdcarticles/PTB/Autodesk-Policy-on-Versioning-for-InfoWorks-ICM-and-InfoWorks-WS-Pro.html

---

## 3. Release Versioning

Utilizado para produtos corporativos e releases de produção.

Exemplo:

Release 2026.1
Release 2026.2
Release 2026.3

Referência:
https://en.wikipedia.org/wiki/Software_versioning

---

# Arquivos que Devem Ser Atualizados

Ao gerar uma nova versão, localizar automaticamente os arquivos existentes no projeto.

Arquivos suportados:

* package.json
* package-lock.json
* composer.json
* composer.lock
* pom.xml
* build.gradle
* gradle.properties
* pyproject.toml
* setup.py
* Cargo.toml
* VERSION
* version.txt
* .env
* config/version.php
* app.json
* manifest.json
* changelog.md

Caso o arquivo não exista, ignorar.

---

# Changelog

Caso não exista:

criar:

changelog.md

Estrutura:

```md
# Changelog

Todas as alterações relevantes deste projeto serão documentadas neste arquivo.
```

Ao gerar uma nova versão:

Adicionar:

```md
## [1.5.0] - 2026-06-12

### Tipo
Feature

### Adicionado
- Cadastro de clientes
- Integração com ERP

### Corrigido
- Erro no cálculo de comissão

### Alterado
- Melhorias de performance
```

---

# Fluxo Obrigatório

## Etapa 1 — Descobrir versão atual

Localizar a versão atual nos arquivos do projeto.

Prioridade:

1. package.json
2. composer.json
3. VERSION
4. version.txt
5. changelog.md

Exibir:

```text
Versão atual encontrada: 1.4.2
```

---

## Etapa 2 — Solicitar versão

Perguntar:

```text
Deseja informar manualmente a nova versão?

[1] Sim
[2] Não
```

Se SIM:

Solicitar:

```text
Informe a versão:
```

Exemplo:

```text
1.5.0
```

---

Se NÃO:

Gerar automaticamente.

---

## Etapa 3 — Tipo da alteração

Perguntar:

```text
Qual o tipo da alteração?
```

Opções:

```text
feature
enhancement
hotfix
bugfix
project
change-breaking
new-version
```

Mapeamento:

| Tipo            | Incremento |
| --------------- | ---------- |
| bugfix          | PATCH      |
| hotfix          | PATCH      |
| enhancement     | MINOR      |
| feature         | MINOR      |
| project         | MAJOR      |
| new-version     | MAJOR      |
| change-breaking | MAJOR      |

Exemplo:

```text
Versão Atual: 1.4.2
Tipo: feature

Nova Versão Sugerida:
1.5.0
```

---

## Etapa 4 — Release Notes

Perguntar:

```text
Informe as alterações desta versão:
```

Permitir múltiplos itens.

Exemplo:

```text
- Novo dashboard
- Correção do login
- Ajuste de permissões
```

Essas informações deverão alimentar:

* changelog.md
* Git Release Notes

---

## Etapa 5 — Atualização dos Arquivos

Perguntar:

```text
Deseja atualizar automaticamente os arquivos de versão?

[1] Sim
[2] Não
```

Se SIM:

Atualizar todos os arquivos compatíveis encontrados.

Exemplo:

package.json

```json
{
  "version": "1.5.0"
}
```

composer.json

```json
{
  "version": "1.5.0"
}
```

---

## Etapa 6 — Gerar Release Git

Perguntar:

```text
Deseja gerar uma Release no Git?

[1] Sim
[2] Não
```

---

## Etapa 7 — Seleção da Branch

Obter automaticamente:

```bash
git branch --show-current
```

Exemplo:

```text
Branch atual:
develop
```

Perguntar:

```text
Branch alvo da release:
```

Se vazio:

Utilizar a branch atual.

Exibir:

```text
Branch selecionada:
develop

Deseja continuar?

[1] Sim
[2] Não
```

---

## Etapa 8 — Preparação da Release

Gerar:

### Tag

```text
v1.5.0
```

### Release Title

```text
Release v1.5.0
```

### Release Notes

Baseado no changelog informado.

Exemplo:

```text
# Release v1.5.0

## Adicionado
- Novo dashboard

## Corrigido
- Login

## Alterado
- Permissões
```

---

## Etapa 9 — Resumo Final

Exibir:

```text
==============================
Resumo da Release
==============================

Versão Atual:
1.4.2

Nova Versão:
1.5.0

Tipo:
feature

Branch:
develop

Tag:
v1.5.0

Arquivos Atualizados:
- package.json
- composer.json
- changelog.md

Release Git:
Sim
```

---

## Etapa 10 — Confirmação Final

Perguntar:

```text
Deseja prosseguir?

[1] Sim
[2] Não
```

---

# Cancelamento

Caso o usuário responda NÃO:

Executar rollback completo.

Reverter:

* package.json
* composer.json
* changelog.md
* VERSION
* demais arquivos alterados

Remover:

* commits temporários
* tags temporárias

Exibir:

```text
Processo cancelado.

Todas as alterações foram revertidas.
```

---

# Execução

Caso o usuário confirme:

Executar:

```bash
git add .
git commit -m "chore(release): v1.5.0"
git tag -a v1.5.0 -m "Release v1.5.0"
git push origin develop
git push origin v1.5.0
```

Caso o provedor suporte Releases:

GitHub:

```bash
gh release create v1.5.0
```

GitLab:

```bash
glab release create v1.5.0
```

Bitbucket:

Utilizar API correspondente.

---

# Regras Obrigatórias

* Nunca alterar versões sem confirmação explícita.
* Sempre exibir preview das alterações.
* Sempre gerar changelog.
* Sempre exibir os arquivos afetados.
* Sempre permitir rollback.
* Sempre validar se a versão já existe.
* Nunca sobrescrever tags existentes.
* Sempre seguir SemVer quando o usuário não informar uma versão.
* Sempre criar backup antes de alterar arquivos.
* Sempre registrar a data da release.
* Sempre utilizar o padrão vX.Y.Z para tags Git.
* Sempre solicitar confirmação final antes de executar comandos Git.
* Em caso de erro, interromper imediatamente e restaurar o estado anterior.

# Resultado Esperado

Ao final do processo o sistema deve:

* Atualizar todos os arquivos de versão.
* Atualizar ou criar changelog.md.
* Gerar release notes.
* Gerar tag Git.
* Publicar release.
* Permitir rollback seguro.
* Exibir um resumo completo da operação executada.
