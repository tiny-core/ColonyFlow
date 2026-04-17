# Phase 15: Operabilidade + Resiliencia (doctor + persistencia + circuit breaker) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar melhorias operacionais e de resiliencia, focadas em:
1) `startup doctor`: modo de diagnostico rapido in-world (sem depender do instalador), mostrando status de HTTP, perifericos, ME, config e sugestoes de acao.
2) Persistencia de jobs: salvar estado minimo de jobs em disco para retomar apos reboot/crash e evitar duplicar crafts.
3) Circuit breaker/backoff do ME: reduzir spam de chamadas e estabilizar comportamento quando o ME estiver oscilando/offline.

Nao mudar regras de equivalencia/tier nem o fluxo principal de craft/entrega alem do necessario para robustez.
</domain>

<decisions>
## Implementation Decisions

### startup doctor
- **D-01:** Adicionar modo `doctor` ao `startup.lua` (similar a `startup test/map/config`).
- **D-02:** Saida curta (ASCII) com:
  - HTTP: OK/OFF/BLOCKED (quando `http.checkURL` existir)
  - Perifericos: colonyIntegrator/meBridge/modem/monitores (present/absent)
  - ME: Online/Offline (grid)
  - Config: valido/invalido (chaves essenciais, enums)
  - Acoes sugeridas (ex.: "Ajuste [peripherals] me_bridge=..."; "Habilite HTTP no servidor"; "Rode tools/install.lua doctor")

### Persistencia de jobs
- **D-03:** Persistir somente o minimo para retomar e evitar duplicar: request id, chosen, status, missing, started_at, retry_at, last_err.
- **D-04:** Armazenar em `data/state.json` com escrita atomica (via `Util.writeFileAtomic`) e compactacao simples.
- **D-05:** Retomada: no boot, carregar `data/state.json` e reaplicar em `state.work` (engine), com saneamento (expirar jobs antigos).

### Circuit breaker / backoff ME
- **D-06:** Se `ME:isOnline()` falhar repetidamente, entrar em modo "degraded" por um periodo (ex.: 30-120s), evitando chamar ME em todos ticks.
- **D-07:** Expor estado no `state` para UI/log (ex.: `state.health.me_degraded=true`, `next_me_retry_at`).

</decisions>

<canonical_refs>
## Canonical References

- `startup.lua` — entrypoint e modos (test/map/config)
- `modules/engine.lua` — estado de `state.work` e loop de processamento
- `modules/me.lua` — `ME:isOnline()` e chamadas ME
- `lib/util.lua` — JSON e escrita atomica
- `lib/config_schema.lua` — validacao de configuracao (para doctor)
- `modules/peripherals.lua` — discovery e mensagens acionaveis
</canonical_refs>

---
*Phase: 15-operabilidade-resiliencia-doctor-persistencia-circuit-breaker*
