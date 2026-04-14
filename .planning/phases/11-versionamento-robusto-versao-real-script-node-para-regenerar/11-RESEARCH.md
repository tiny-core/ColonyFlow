# Phase 11: Versionamento robusto (versao real + script Node para regenerar manifest) - Research

## Summary

Hoje o instalador (`tools/install.lua`) grava em `data/version.json`:
- `ref` (hoje sempre `master`)
- `manifest_url`
- `manifest_version` (schema do manifesto, nao a versao do projeto)
- `managed_files`

O `manifest.json` atual nao carrega uma versao "real" do projeto (ex.: `1.2.3`) e nao ha um processo deterministico para regenerar a lista/metadata de arquivos. Isso limita:
- Auditoria: nao da para saber qual release/versao esta instalada, apenas o schema do manifesto.
- Update check: fases futuras precisam comparar "versao instalada vs versao disponivel".
- Robustez: manifesto sem `size` perde uma camada simples de integridade na hora do download.

Esta fase deve introduzir:
1) Um campo de versao do projeto no `manifest.json` (ex.: `version: "0.11.0"`)
2) Persistencia dessa versao em `data/version.json`
3) Um script Node no repo para regenerar `manifest.json` de forma deterministica (incluindo `generated_utc`, lista ordenada e `size` quando aplicavel)

## Codebase Map (relevante)

### Instalador / Manifesto
- `tools/install.lua`
  - `validateManifest(manifest)` valida apenas `manifest_version` (numero) e `files` (lista).
  - `downloadToTemp(...)` suporta `size` (se presente no manifesto).
  - `writeInstalledVersion(...)` grava `manifest_version` e `managed_files`.
- `manifest.json`
  - Schema atual: `{ manifest_version, generated_utc?, files:[{path,size?,preserve?}] }`
  - Nao possui `version`.

### UX / Mensagens
- O projeto tem padrao de mensagens operacionais em ASCII (sem acentos) quando exibidas na UI/terminal in-game.
- Mudancas no instalador devem manter mensagens ASCII para evitar glifos quebrados no CC.

## Recommended Approach

### 1) Definir uma "versao real" (SemVer simples)
- Adotar SemVer simples: `MAJOR.MINOR.PATCH` (somente numeros).
- Fonte canonica no repo:
  - Arquivo `VERSION` no root contendo apenas a string (ex.: `0.11.0`).
  - O `manifest.json` carrega `"version": "<conteudo do VERSION>"`.

### 2) Atualizar o schema do manifesto (mantendo compatibilidade)
- Manter `manifest_version: 2` como schema.
- Adicionar campos:
  - `version` (string SemVer, obrigatorio para o instalador a partir desta fase)
  - `generated_utc` continua opcional (string) para debugging
- Reforcar validacao no instalador:
  - `version` presente e valida (regex simples `^%d+%.%d+%.%d+$`)
  - `files[*].path` continua com validacao de path seguro

### 3) Persistir versao instalada (data/version.json)
- Estender `data/version.json` para incluir:
  - `version` (do manifesto remoto)
  - `manifest_generated_utc` (opcional, se presente)
- Manter chaves atuais para retrocompatibilidade e leitura futura.

### 4) Script Node para regenerar manifest (deterministico)
- Adicionar `tools/gen_manifest.js` (Node >= 16, sem dependencias externas) que:
  - Le `VERSION`
  - Varre o working tree e gera lista de arquivos gerenciados (ordenada)
  - Aplica `preserve=true` para arquivos de usuario (ex.: `config.ini`, `data/mappings.json`)
  - Calcula `size` (bytes) para cada arquivo
  - Escreve `manifest.json` com `pretty` e `generated_utc` (UTC)
- Excluir explicitamente:
  - `.planning/`, `.trae/`, `logs/`, `data/install.json`, `data/version.json`, `data/backups/`, `data/.install_tmp/`
  - Qualquer arquivo temporario / editor (ex.: `*.tmp`)

### 5) Preparar suporte reutilizavel para fases futuras
- Criar um helper simples `lib/version.lua` para:
  - Validar SemVer (`isValid("x.y.z")`)
  - Comparar (`compare(a,b)` retornando -1/0/1)
  - Ler `data/version.json` e retornar `installed_version` quando existir

## Risks / Pitfalls

- **Quebra de installs antigos:** tornar `version` obrigatorio no instalador exige que o `manifest.json` remoto seja atualizado em conjunto.
- **Falsa sensacao de "ref fixa":** o instalador baixa sempre `master`; sem tags/SHAs, a versao real deve ser mantida corretamente no repo para nao mentir.
- **Manifesto nao deterministico:** ordem de arquivos ou inclusao acidental de arquivos de dev pode gerar updates ruidosos e orfaos inesperados.
- **Strings com acentos no instalador:** podem causar exibicao ruim no CC; preferir ASCII.

## Validation Architecture

### Objetivo de validacao
Garantir que:
1) `manifest.json` inclui `version` valida e (quando gerado pelo script) `size` para todos os arquivos
2) O instalador rejeita manifesto sem `version` (mensagem clara em ASCII)
3) `data/version.json` passa a incluir `version` apos `install`/`update`
4) O script Node gera um `manifest.json` deterministico e consistente com o que o instalador espera

### Estrategia de testes (CC: Tweaked + offline)
- Unit tests (CC):
  - Testar `lib/version.lua` (validacao e compare).
  - (Opcional) adicionar teste de "schema" do manifesto via funcao extraida ou helper dedicado.
- Verificacoes offline:
  - Rodar `node tools/gen_manifest.js` e checar que `manifest.json` contem `version`, `generated_utc` e `size` em todas entradas.
- Verificacoes in-world:
  - Rodar `tools/install.lua doctor` (se aplicavel) e `tools/install.lua update` em um setup existente; confirmar que `data/version.json` contem `version`.

---

*Phase: 11-versionamento-robusto-versao-real-script-node-para-regenerar*
