# Phase 21: Retry com Prioridade

## Goal
Requests que estão em `waiting_retry` há mais tempo ganham prioridade no próximo tick em vez de FIFO ou ordem arbitrária. Evita que uma request travada no fim da lista fique sendo ignorada indefinidamente.

## Problem
O cursor do scheduler processa requests em ordem de chegada. Uma request que entrou em waiting_retry logo no primeiro tick pode ficar no fim da fila por muito tempo se novas requests chegarem continuamente.

## Behavior
- Ao construir a lista de trabalho no tick, requests em `waiting_retry` cuja `next_retry` já passou são ordenadas por `started_at_ms` (mais antigas primeiro)
- Requests novas ainda entram na ordem do MineColonies (prioridade menor que retries pendentes)
- Nenhuma mudança na lógica de budget/cursor — só a ordenação da fila
- `state.work` não muda de estrutura
- Testes: duas requests em retry, a mais antiga deve ser processada primeiro

## Files Likely Touched
- `modules/engine.lua` — função que constrói a lista de trabalho do tick
- `tests/run.lua` — novos testes

## Depends On
Phase 19 (complete)

## Complexity
Low — mudança cirúrgica na ordenação dentro de engine.lua
