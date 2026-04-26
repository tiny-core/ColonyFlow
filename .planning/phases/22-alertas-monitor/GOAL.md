# Phase 22: Alertas de Monitor

## Goal
Requests presas por mais de N minutos (blocked_by_tier, nao_craftavel, waiting_retry longa) aparecem em destaque colorido no monitor com tempo de espera visível.

## Behavior
- Threshold configurável: `[observability] alert_stuck_minutes = 5`
- Monitor de requests: linha presa fica vermelha/amarela com sufixo "Xm"
- Máx 1 linha de alerta no monitor de status (resumo: "N presas >Xm")
- Não bloqueia o loop principal; só afeta renderização

## Files Likely Touched
- `components/ui.lua`, `modules/engine.lua` (campo `stuck_since_ms`), `lib/config.lua`, `tests/run.lua`

## Depends On
Phase 19 (complete)

## Complexity
Low-Medium
