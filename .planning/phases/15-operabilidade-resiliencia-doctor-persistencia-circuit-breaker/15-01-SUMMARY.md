---
phase: 15-operabilidade-resiliencia-doctor-persistencia-circuit-breaker
plan: "01"
subsystem: operability
tags: [doctor, persistence, circuit-breaker, me, tests]
requires:
  - phase: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi
    provides: baseline de update-check + infraestrutura existente
provides:
  - `startup doctor` (diagnostico rapido in-world, ASCII-only)
  - persistencia leve de jobs em `data/state.json` (schema v1)
  - circuit breaker/backoff do ME via `state.health.me_degraded`
affects: [startup, engine, me, tests]
tech-stack:
  added: []
  patterns:
    - estado_persistido_minimo_com_escrita_atomica
    - circuit_breaker_por_health_com_backoff_exponencial_curto
key-files:
  created:
    - modules/doctor.lua
    - modules/persistence.lua
  modified:
    - startup.lua
    - modules/engine.lua
    - modules/me.lua
    - tests/run.lua
    - .planning/phases/15-operabilidade-resiliencia-doctor-persistencia-circuit-breaker/15-VERIFICATION.md
requirements-completed: []
duration: n/a
completed: 2026-04-19
---

# Phase 15 Plan 01: Operabilidade + Resiliencia (doctor + persistencia + circuit breaker) Summary

## Accomplishments

- Adiciona modo `startup doctor` no `startup.lua`, chamando `modules/doctor.lua` com output curto e ASCII-only (HTTP/peripherals/ME/config + acoes sugeridas)
- Cria persistencia leve de jobs em `data/state.json` (schema `v=1`) com escrita atomica e load tolerante a JSON invalido
- Implementa circuit breaker/backoff do ME no wrapper `modules/me.lua` usando `state.health.me_degraded` e `state.health.next_me_retry_at_ms`
- Ajusta o `Engine:tick()` para respeitar o degraded mode sem spammar logs em loop
- Adiciona testes unitarios para persistencia e circuit breaker no harness existente (`tests/run.lua`)
- Atualiza checklist manual de verificacao da fase 15

## Verification

- Automated: `startup test`
- Manual (in-world): seguir `15-VERIFICATION.md` (doctor, reboot com job em andamento, ME offline/online)

## Notes

- O summary nao inclui commits automaticamente; use seu fluxo de versionamento/commit quando desejar.

---
*Phase: 15-operabilidade-resiliencia-doctor-persistencia-circuit-breaker*
*Completed: 2026-04-19*
