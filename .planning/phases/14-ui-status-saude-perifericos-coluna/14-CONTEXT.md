# Phase 14: UI Status - Saude de perifericos (coluna alinhada) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar no Monitor 2 (Status) uma coluna/tabela alinhada verticalmente exibindo o status dos perifericos essenciais para o sistema funcionar, lado a lado com os contadores de operacao.

Exemplo desejado:
- `ME Bridge: Online` (verde) / `Offline` (vermelho)
- `Colony: Online/Offline`
- `Modem: Online/Offline`
- `Mon Req: Online/Offline`
- `Mon Stat: Online/Offline`

O layout deve ser "coluna nova" ao lado dos outros status, com alinhamento vertical (como uma tabela lado a lado).
</domain>

<decisions>
## Implementation Decisions

- **D-01:** A coluna aparece na secao OPERACAO do Monitor 2, ao lado das linhas existentes (Requisicoes/Entregues/Crafts/Substituicoes/Erros).
- **D-02:** Usar cores para o valor:
  - Online/OK: verde
  - Offline/Ausente: vermelho
  - Desconhecido/NA: cinza
- **D-03:** "ME Bridge: Online" deve refletir `ME:isOnline()` (grid online), nao apenas periférico presente.
- **D-04:** O calculo do status deve ser cacheado para nao spammar chamadas de perifericos no tick da UI.
- **D-05:** ASCII-only nos textos exibidos.

</decisions>

<canonical_refs>
## Canonical References

- `components/ui.lua` — renderStatus atual e padrao de renderizacao por linhas
- `modules/peripherals.lua` — lista de devices resolvidos (colonyIntegrator, meBridge, modem, monitores)
- `modules/me.lua` — `ME:isOnline()` para status real do ME
- `lib/cache.lua` — TTL para cachear status (ex.: 1-3s)
- `modules/engine.lua` / `modules/scheduler.lua` — ponto para atualizar um snapshot de saude em background
</canonical_refs>

---
*Phase: 14-ui-status-saude-perifericos-coluna*
