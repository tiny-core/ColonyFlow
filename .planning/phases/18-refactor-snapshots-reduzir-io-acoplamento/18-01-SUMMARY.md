---
phase: 18-refactor-snapshots-reduzir-io-acoplamento
plan: "01"
subsystem: architecture
tags: [snapshot, engine, ui, refactor, tests]
requires:
  - phase: 17-scheduler-budget-limites-por-tick
    provides: scheduler paralelo + budgets/throttle/metrics existentes
provides:
  - snapshot canonico por tick (`state.snapshot`) produzido pelo engine
  - UI renderizando via snapshot (reduz leitura direta de `state.*`)
  - testes unitarios cobrindo build de snapshot e selecao de view pela UI
affects: [engine, ui, scheduler, tests]
tech-stack:
  added: []
  patterns:
    - snapshot_por_tick_com_swap_de_referencia
    - renderizacao_por_view_compat_snapshot_ou_state
key-files:
  created:
    - modules/snapshot.lua
  modified:
    - modules/engine.lua
    - components/ui.lua
    - tests/run.lua
    - .planning/phases/18-refactor-snapshots-reduzir-io-acoplamento/18-VERIFICATION.md
    - .planning/phases/18-refactor-snapshots-reduzir-io-acoplamento/18-VALIDATION.md
requirements-completed: []
duration: n/a
completed: 2026-04-21
---

# Phase 18 Plan 01: Refactor por Snapshots (reduzir acoplamento/IO) Summary

## Accomplishments

- Cria `modules/snapshot.lua` com `Snapshot.build(state)` (sem IO) e chaves estaveis para consumo pela UI.
- Atualiza `Engine:tick()` para publicar `state.snapshot` ao final do tick e tambem em retornos precoces (swap de referencia).
- Atualiza UI para renderizar a partir de `state.snapshot` quando disponivel, com fallback para `state` (compat).
- Remove dependencia direta de `peripheral.getName` na UI, usando `devices.*Name`.
- Adiciona testes unitarios para defaults do snapshot e para a selecao de view (snapshot vs state) no tick da UI.

## Verification

- Automated: `startup test`
- Manual (in-world): seguir `18-VERIFICATION.md`

## Notes

- O snapshot atual e introdutorio e mantem compat com `state.*` (mudanca incremental).

---
*Phase: 18-refactor-snapshots-reduzir-io-acoplamento*
*Completed: 2026-04-21*
