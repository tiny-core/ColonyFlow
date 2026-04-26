# Phase 26: Modo Dry-Run

## Goal
`startup dryrun` executa o engine sem exportar itens nem iniciar crafts. Loga o que faria em cada tick — útil para validar mapeamentos e configuração antes de ativar o sistema em produção.

## Behavior
- Flag `state.dry_run = true` injetada pelo bootstrap quando modo dryrun
- `modules/me.lua`: exportItem e craftItem verificam flag e retornam sucesso simulado sem chamar o periférico
- Log especial: `[DRY-RUN] exportaria X de mod:item para rack_0`
- UI mostra "[DRY-RUN]" no header
- Config, mapeamentos e periféricos são lidos normalmente (apenas escrita/craft bloqueados)

## Files Likely Touched
- `startup.lua`, `lib/bootstrap.lua`, `modules/me.lua`, `components/ui.lua`, `tests/run.lua`

## Depends On
Phase 19 (complete)

## Complexity
Low-Medium
