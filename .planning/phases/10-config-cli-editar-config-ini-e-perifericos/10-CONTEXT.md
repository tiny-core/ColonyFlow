# Phase 10: Config CLI (editar config.ini e perifericos) - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar um CLI no terminal para editar `config.ini` (com foco em perifericos, core/logs e delivery) e validar configuracao de perifericos antes de salvar, com backup/rollback seguro.

</domain>

<decisions>
## Implementation Decisions

### Escopo do CLI
- **D-01:** O CLI edita: `[peripherals]` + `[core]` (inclui chaves de logs) + `[delivery]`. Outras secoes ficam fora do menu nesta fase.
- **D-02:** Mensagens exibidas no terminal/monitor devem evitar acentos e caracteres especiais (ASCII apenas) para compatibilidade e consistencia.

### Edicao e Salvamento do `config.ini`
- **D-03:** Salvamento por patch in-place: alterar somente linhas `key=value` e inserir chaves faltantes na secao correta, preservando comentarios, ordem e chaves desconhecidas.
- **D-04:** Validacao e bloqueio: valores invalidos impedem salvar; o CLI explica o erro e mostra exemplos validos.

### Perifericos (listar/validar)
- **D-05:** Quando um periferico configurado nao existir, o CLI tenta auto-detect por tipo, sugere um nome e pede confirmacao/ajuste.
- **D-06:** Validacao minima: `peripheral.isPresent` + `peripheral.wrap` (sem checar metodos obrigatorios).
- **D-07:** `monitor_requests` e `monitor_status` nao podem apontar para o mesmo nome; o CLI impede salvar nesse caso.
- **D-08:** Fluxo: Editar -> Testar -> Salvar. O teste roda antes de gravar e o salvar so acontece se estiver OK (ou mediante confirmacao quando aplicavel).

### Comandos e UX
- **D-09:** Invocacao via `startup config` (novo modo no `startup.lua`) chamando `modules/config_cli.lua`.
- **D-10:** UI do CLI em menu por blocos: Perifericos | Core+Logs | Delivery | Sair (com submenus e validacao).
- **D-11:** Usar cores quando disponivel (via `term.isColor()`), com fallback monocromatico.

### Backup / Rollback
- **D-12:** Criar backup sempre antes de salvar.
- **D-13:** Backups em `data/backups/` com nome contendo timestamp.
- **D-14:** Gravacao atomica: escrever `config.ini.tmp`, validar, depois trocar para `config.ini`.
- **D-15:** Preview antes de salvar: lista de chaves alteradas no formato `secao.chave: antigo -> novo`.

### Claude's Discretion
- Heuristica exata de auto-detect e prioridade quando houver varios candidatos por tipo (mantendo previsivel e explicavel).
- Layout exato do menu e atalhos (desde que consistentes com o padrao do `mapping_cli`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e constraints
- `.planning/ROADMAP.md` — definicao da Fase 10 e dependencias
- `.planning/REQUIREMENTS.md` — requisitos de configuracao e robustez (CFG-01..04, ROB-01..02)
- `.planning/PROJECT.md` — constraints globais (operacao autonoma, logs em PT, estrutura de arquivos)
- `.planning/phases/04-ui-configuracao-operacional/04-CONTEXT.md` — decisoes de UX/TUI do editor (menu guiado)
- `.planning/phases/07-auto-setup-compatibilidade-mp/07-CONTEXT.md` — comportamento esperado de defaults e diagnostico

### Codigo existente (pontos de integracao)
- `startup.lua` — padrao atual de CLI (`startup test`, `startup map`)
- `lib/config.lua` — parser INI + defaults (nao tem writer)
- `modules/peripherals.lua` — discover/validacao e mensagens de hint
- `modules/mapping_cli.lua` — padrao TUI (selectList, cores, navegacao)
- `lib/util.lua` — utilitarios de I/O e helpers (read/write/ensureDir)
- `config.ini` — formato atual e chaves existentes

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mapping_cli.lua` ja tem uma base de TUI (menu, cores, navegacao) reutilizavel para o novo CLI.
- `modules/peripherals.lua` ja resolve e valida perifericos, alem de gerar mensagens acionaveis quando algo esta faltando.
- `lib/config.lua` ja tem defaults e parse de INI; pode ser usado para carregar/validar e para saber quais chaves existem.

### Established Patterns
- `startup.lua` usa `shell.run(...)` para iniciar CLIs especificos por modo.
- Mensagens operacionais e logs sao em portugues; o runtime deve ser resiliente a perifericos ausentes.

### Integration Points
- O CLI escreve em `config.ini` e depois o runtime (`lib/bootstrap.lua`/engine) consome as chaves.
- O teste de perifericos deve usar o mesmo caminho de discovery do runtime para evitar divergencia.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-config-cli-editar-config-ini-e-perifericos*
*Context gathered: 2026-04-12*
