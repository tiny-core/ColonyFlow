---
phase: 13-operabilidade-update-check-config-backoff-detalhes
plan: "01"
subsystem: operability
tags: [update-check, config, backoff, ui, tests]

requires:
  - phase: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi
    provides: update-check baseline + cache + header UI
provides:
  - config.ini [update] (enabled/ttl/backoff)
  - retry/backoff com cap para erro/HTTP off, separado do TTL de sucesso
  - view de detalhes do update-check no Monitor 2 ([UPD])
  - testes unitarios para cache/backoff/TTL
affects: [ui, scheduler, update-check, operability]

tech-stack:
  added: []
  patterns:
    - ttl_por_sucesso_e_retry_por_erro
    - persistencia_de_estado_operacional_no_cache
    - ui_ascii_only_com_truncamento

key-files:
  created: []
  modified:
    - config.ini
    - lib/config.lua
    - modules/update_check.lua
    - modules/scheduler.lua
    - components/ui.lua
    - tests/run.lua
    - .planning/phases/13-operabilidade-update-check-config-backoff-detalhes/13-VERIFICATION.md

key-decisions:
  - "Separar TTL de sucesso (last_success_at_ms) do retry/backoff de erro (next_retry_at_ms)."
  - "Expor detalhes do update-check via view dedicada no Monitor 2 acessada por [UPD], mantendo a tela principal discreta."

patterns-established:
  - "UpdateCheck: estado persistido em data/update_check.json com last_attempt/last_success/fail_count/next_retry."
  - "Scheduler: logar em INFO apenas em mudanca de status ou quando uma tentativa ocorre (via last_attempt_at_ms), evitando spam."

requirements-completed: []

duration: n/a
completed: 2026-04-18
---

# Phase 13 Plan 01: Operabilidade do update-check (config + backoff + detalhes) Summary

**Update-check passa a ser configuravel, com TTL separado de retry/backoff em erro e uma tela de detalhes no Monitor 2 acessivel por [UPD].**

## Performance

- **Tasks:** 6
- **Files modified:** 7

## Accomplishments
- Configura `[update]` no config.ini/defaults (enabled, ttl_hours, retry_seconds, error_backoff_max_seconds)
- Implementa retry/backoff com cap e compatibilidade com cache antigo, sem "travar" por TTL em erro/HTTP off
- Adiciona view de detalhes no monitor de status com campos operacionais (ASCII-only e truncamento)
- Cobre comportamento com testes sem HTTP real (TTL vs erro, cap de backoff, normalizacao de cache)

## Task Commits

Cada tarefa foi commitada de forma atomica:

1. **Task 1: Config [update]** - `808b4b8` (chore)
2. **Task 2: TTL vs retry/backoff** - `b44de76` (feat)
3. **Task 3: Scheduler enabled/log sem spam** - `d121d65` (feat)
4. **Task 4: UI detalhes no Monitor 2** - `64b99d7` (feat)
5. **Task 5: Testes de cache/backoff/TTL** - `c479f04` (test)
6. **Task 6: Checklist de verificacao + tracking** - (docs)

## Files Created/Modified
- `lib/config.lua` - defaults do config.ini com secao [update]
- `config.ini` - documenta defaults da secao [update]
- `modules/update_check.lua` - estado persistido + calculo de TTL por sucesso e retry/backoff por erro
- `modules/scheduler.lua` - respeita update.enabled e loga tentativas sem spam
- `components/ui.lua` - botao [UPD] e view de detalhes (ASCII-only)
- `tests/run.lua` - testes para normalizacao e politica de retry/backoff/TTL
- `.planning/phases/13-operabilidade-update-check-config-backoff-detalhes/13-VERIFICATION.md` - checklist manual alinhado com a implementacao

## Decisions Made
None - seguiu as decisoes registradas em 13-CONTEXT.md.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Update-check agora tem sinalizacao operacional e modo disabled; pronto para evolucoes de UI/status na Phase 14.

---
*Phase: 13-operabilidade-update-check-config-backoff-detalhes*
*Completed: 2026-04-18*
