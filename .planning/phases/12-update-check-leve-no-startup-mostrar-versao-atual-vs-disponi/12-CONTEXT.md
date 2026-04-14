# Phase 12: Update check leve no startup + mostrar versao atual vs disponivel na UI - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar um update-check leve, nao-bloqueante, que compara a versao instalada com a versao disponivel no repositorio (via manifesto remoto), exibindo o resultado de forma discreta na UI (dual-monitor) e registrando em log sem interromper a operacao.

</domain>

<decisions>
## Implementation Decisions

### Fonte e URL do update-check
- **D-01:** A versao disponivel vem do `manifest.json` remoto (mesmo artefato usado pelo instalador), comparada com `data/version.json` local.
- **D-02:** A URL do manifesto remoto e montada a partir de `data/install.json` (com defaults quando campos estiverem ausentes).

### Cache e comportamento de rede
- **D-03:** O update-check roda automaticamente no boot, mas respeita cache persistido com TTL.
- **D-04:** TTL padrao do cache: **6 horas**.
- **D-05:** O update-check roda em **background** (nao pode atrasar o boot do sistema/UI).
- **D-06:** Quando HTTP estiver indisponivel/bloqueado, o sistema indica isso de forma **discreta na UI** (ASCII) e segue operando normalmente.
- **D-07:** Politica de retry no background: **2 tentativas**.
- **D-08:** Se o cache expirou e a checagem remota falhar, manter o ultimo `available` conhecido (marcado como stale/antigo, se aplicavel).

### UI (dual-monitor)
- **D-09:** A versao/estado do update aparece no **header (canto direito)** e, quando houver update, tambem em **banner/linha no Monitor 2 (Status)**.
- **D-10:** Header: formato base **hora + versao instalada** (ex.: `20:15Z 1.2.3`), e quando houver update: `20:15Z 1.2.3->1.2.4`.
- **D-11:** Banner no Monitor 2 quando houver update: mostra **versoes + comando** (ASCII), incluindo acao sugerida.
- **D-12:** Quando nao houver update: nao mostrar marcador extra no header; quando o check estiver indisponivel (HTTP off/bloqueado), mostrar indicador discreto (ex.: `UPD:OFF`) sem banner chamativo.

### Mensagens, logs e acao sugerida
- **D-13:** Nao imprimir mensagem extra no terminal no boot; usar UI + log.
- **D-14:** Nivel de log: **INFO** tanto para update disponivel quanto para falhas/indisponibilidade do check.
- **D-15:** Acao sugerida na UI para atualizar: `tools/install.lua update`.
- **D-16:** Se nao houver versao instalada detectavel (sem `data/version.json`), a UI deve indicar isso e sugerir `tools/install.lua install`.

### Carried forward (prior phases)
- **D-17:** Mensagens exibidas no CC (prints/logs/UI) devem evitar acentos e caracteres especiais (ASCII apenas) para compatibilidade e consistencia.

### Claude's Discretion
- Formato exato do arquivo de cache do update-check (ex.: `data/update.json`) e seus campos (desde que persistam timestamp/available/status).
- Regras de truncamento/abreviacao para caber no width do monitor sem quebrar o layout.
- Como sinalizar visualmente `stale` de forma discreta (sem poluir a tela).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e constraints
- `.planning/ROADMAP.md` — definicao da Fase 12 e dependencias
- `.planning/PROJECT.md` — objetivos e constraints globais (operacao autonoma, UI dual-monitor, observabilidade)
- `.planning/REQUIREMENTS.md` — requisitos de robustez e operacao (ROB-01/02) e constraints de configuracao
- `.planning/phases/10-config-cli-editar-config-ini-e-perifericos/10-CONTEXT.md` — ASCII-only em mensagens e padroes de CLI/config
- `.planning/phases/09-instalador-git/09-CONTEXT.md` — padroes do instalador (manifesto, version.json, preservacao)
- `.planning/phases/11-versionamento-robusto-versao-real-script-node-para-regenerar/11-01-SUMMARY.md` — versao real (SemVer) e persistencia em `data/version.json`

### Codigo existente (pontos de integracao)
- `startup.lua` — entrypoint e modos atuais
- `lib/bootstrap.lua` — inicializacao do state/logger e criacao do UI
- `modules/scheduler.lua` — loops paralelos (engine/ui/eventos) onde um loop de update-check pode encaixar
- `components/ui.lua` — header e render do Monitor 1/2 (onde a versao e exibida)
- `lib/version.lua` — parse/compare semver + leitura de `data/version.json`
- `tools/install.lua` — formato do manifesto remoto e comandos `install/update/doctor`
- `lib/util.lua` — I/O e JSON helpers para persistir cache do update-check
- `lib/logger.lua` — padrao de logs e niveis

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/version.lua` ja valida e compara SemVer e le `data/version.json`.
- `tools/install.lua` ja valida o `manifest.json` remoto e tem helpers HTTP (retry, erros).
- `components/ui.lua` ja mostra `hora + VERSION` no header de ambos monitores e tem padrao de banner/linha.

### Established Patterns
- Bootstrap monta `state` e o `Scheduler` roda loops em paralelo (engine/ui/eventos).
- UI trabalha com renderizacao por diff (`drawText` com buffer) para reduzir flicker.

### Integration Points
- O resultado do update-check deve viver em `state` (ex.: `state.update`) para a UI renderizar sem dependencias globais.

</code_context>

<specifics>
## Specific Ideas

- O update-check nao pode travar o sistema: sempre degradar para estado desconhecido/indisponivel e seguir.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi*
*Context gathered: 2026-04-14*
