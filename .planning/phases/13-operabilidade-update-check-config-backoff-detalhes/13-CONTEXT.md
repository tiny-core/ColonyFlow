# Phase 13: Operabilidade do update-check (config + backoff + detalhes) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Evoluir o update-check (Fase 12) para operar bem em ambientes diversos (SP/MP, HTTP bloqueado, rede instavel), adicionando:
- configuracao em `config.ini` (enable/ttl/backoff)
- backoff previsivel em falhas (sem "travar" por 6h quando der erro/HTTP off)
- uma forma de ver detalhes (ultima checagem, ultimo erro, manifest_url, stale) sem poluir a UI principal

Nao mudar o comportamento core do engine/craft/entrega; foco e observabilidade e operacao.
</domain>

<decisions>
## Implementation Decisions

### Configuracao
- **D-01:** Adicionar secao `[update]` em `config.ini` com chaves:
  - `enabled` (default: true)
  - `ttl_hours` (default: 6)
  - `retry_seconds` (default: 120)
  - `error_backoff_max_seconds` (default: 900)
- **D-02:** Defaults devem ser aplicados via infra existente (`Config.ensureDefaults`) e manter compatibilidade com installs antigos.

### Politica de cache e backoff
- **D-03:** Separar "ultimo sucesso" de "ultima tentativa":
  - Sucesso respeita `ttl_hours`
  - Erro/HTTP off usa retry com backoff (ate `error_backoff_max_seconds`)
- **D-04:** Em erro, manter ultimo `available_version` conhecido e marcar `stale=true` (quando existir).

### UI / detalhes
- **D-05:** Nao adicionar spam visual na tela principal.
- **D-06:** Expor uma tela de detalhes acessivel por toque (ou alternancia de view) no Monitor 2:
  - mostra `installed`, `available`, `status`, `stale`, `last_checked`, `last_success`, `last_err`, `manifest_url`
  - ASCII-only

### Logs
- **D-07:** Logar em INFO apenas em mudanca de status ou quando ocorrer uma tentativa apos expiracao (sem spam por loop).

</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — definicao das fases 12-14
- `.planning/PROJECT.md` — constraints e objetivos globais
- `modules/update_check.lua` — implementacao atual (TTL 6h + cache + HTTP)
- `modules/scheduler.lua` — loop paralelo do update-check
- `lib/config.lua` — ensureDefaults e load/patch de config.ini
- `components/ui.lua` — renderStatus/view modes (pattern de alternar views por monitor_touch)
</canonical_refs>

---
*Phase: 13-operabilidade-update-check-config-backoff-detalhes*
