# Phase 09: Instalador In-Game (Git) - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Permitir instalação e atualização dentro do jogo com um único script (bootstrap), baixando arquivos via HTTP de um repositório Git (raw), com update seguro e preservação de config/dados do usuário por padrão.

</domain>

<decisions>
## Implementation Decisions

### Fonte e Versão
- **D-01:** A ref do repositório é configurável, com padrão apontando para o branch principal (main/latest).
- **D-02:** A origem é apenas o repositório “oficial” (sem suporte a forks/URLs custom via configuração).
- **D-03:** URL/ref ficam em `data/install.json` (config dedicada do instalador).
- **D-04:** A versão instalada é registrada em `data/version.json`.

### Manifesto e Escopo
- **D-05:** O instalador baixa um manifesto do repositório (ex.: `manifest.json`) para obter a lista de arquivos e metadados.
- **D-06:** Validação por arquivo usa tamanho quando disponível no manifesto; quando não disponível, valida HTTP + conteúdo não vazio.
- **D-07:** “Gerenciados” = somente os caminhos explicitamente listados no manifesto (update sobrescreve só esses).
- **D-08:** No update, arquivos gerenciados que não aparecem mais no manifesto (órfãos) são removidos.

### Preservação e Segurança
- **D-09:** Preserva por padrão: `config.ini`, `data/mappings.json`, `data/install.json`, `data/version.json`.
- **D-10:** Update cria backup por snapshot em pasta dedicada antes de aplicar mudanças.
- **D-11:** Update segue 2 fases: download/validação em temporário → aplicar/replace.
- **D-12:** Em falha (HTTP/validação/disco), faz rollback automático a partir do snapshot.

### UX e Comandos
- **D-13:** Bootstrap em computador limpo deve ser possível com um 1-liner do tipo `wget run <raw-url>/install.lua` (ou equivalente).
- **D-14:** O `install.lua` expõe comandos/modos: `install`, `update`, `doctor`.
- **D-15:** Após instalar, o instalador é mantido como ferramenta local em `tools/` (não fica na raiz).
- **D-16:** Saída padrão mostra status por arquivo + resumo final (contadores e resultado).

### Claude's Discretion
- Valores padrão de timeouts, quantidade de retries, e o layout exato do resumo (mantendo mensagens acionáveis em PT-BR).
- Nome exato e formato do arquivo de manifesto (desde que seja um único arquivo raw no repo e contenha caminhos + `size` opcional).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e requisitos
- `.planning/ROADMAP.md` — definição da Fase 9 (goal, inclui e success criteria)
- `.planning/REQUIREMENTS.md` — constraints relevantes (CFG-01, ROB-01) e preservação de dados/config
- `.planning/PROJECT.md` — constraints globais (logs PT, operação autônoma, estrutura de arquivos)
- `.planning/phases/01-fundacao-operacional/01-CONTEXT.md` — decisões globais de estrutura (`startup.lua`/`config.ini` na raiz)

### Código existente (padrões/utilitários)
- `startup.lua` — entrypoint atual e padrões de CLI (ex.: `startup test`, `startup map`)
- `lib/util.lua` — utilitários de I/O (read/write, ensureDir, JSON)
- `lib/logger.lua` — padrões de logs em PT e rotação (`logs/`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/util.lua` já oferece `ensureDir`, `readFile`, `writeFile` e JSON via `textutils.serializeJSON`/`unserializeJSON`.
- `lib/logger.lua` já define padrão de mensagens em português e rotação em `logs/` (útil para o modo `doctor` e para auditoria).

### Established Patterns
- Root do computador hoje contém `startup.lua` e `config.ini`; o resto fica em subpastas funcionais (lib/modules/components/tests/data/logs).
- Saída em terminal é usada como canal principal de feedback (logs também imprimem no terminal).

### Integration Points
- `startup.lua` pode futuramente expor um modo `install`/`update` que chame `tools/install.lua`, se fizer sentido para ergonomia.

</code_context>

<specifics>
## Specific Ideas

- “Doctor” deve detectar HTTP desabilitado e emitir instruções acionáveis (o que habilitar e onde, em termos do ambiente CC: Tweaked do modpack/servidor).
- O update deve preservar `config.ini` e `data/mappings.json` sem exigir flags, e deixar isso explícito no resumo final (“preservado”).

</specifics>

<deferred>
## Deferred Ideas

- Assinatura criptográfica completa do conteúdo (hash+assinatura) para hardening futuro.

</deferred>

---

*Phase: 09-instalador-git*
*Context gathered: 2026-04-12*
