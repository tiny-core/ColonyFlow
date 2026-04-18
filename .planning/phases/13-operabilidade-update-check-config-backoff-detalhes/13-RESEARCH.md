# Phase 13: Operabilidade do update-check (config + backoff + detalhes) - Research

## Summary

A implementacao atual do update-check usa um unico timestamp (`checked_at_ms`) + TTL (6h) para decidir quando checar novamente. Isso causa um problema operacional: quando ocorre erro (HTTP off/bloqueado/falha remota), o sistema marca `checked_at_ms` e passa a dormir por ate 6h, escondendo o fato de que esta apenas "aguardando TTL", em vez de ter uma politica de retry previsivel.

Esta fase deve:
- tornar o update-check configuravel via `config.ini` (enable/ttl/backoff)
- separar "ultimo sucesso" de "ultima tentativa" para que:
  - sucesso continue respeitando TTL (horas)
  - erro/HTTP off use retry com backoff limitado (segundos)
- expor detalhes operacionais no Monitor 2 sem poluir a view principal

## Codebase Map (relevante)

- `modules/update_check.lua`
  - Cache: `data/update_check.json` com `checked_at_ms`, `ttl_ms`, `available_version`, `status`, `err`, `manifest_url`, `stale`
  - `tick(state)` retorna quantos segundos o Scheduler deve dormir
  - Em erro, grava `checked_at_ms` e volta a dormir por TTL (problema atual)
- `modules/scheduler.lua`
  - `loopUpdateCheck()` chama `UpdateCheck.tick(state, { tries = 2 })`
  - Logs somente quando uma "chave de status" muda (status/versoes/stale/err)
- `lib/config.lua`
  - `Config.ensureDefaults()` escreve um `DEFAULT_INI` quando `config.ini` nao existe
  - `Config.getBool/getNumber()` ja oferecem fallback de defaults em runtime
- `components/ui.lua`
  - Header do Monitor 2 usa `UpdateCheck.formatHeaderRight(state, w)`
  - `statusView` tem apenas `main` e `nocraft`; padrao de toggle via `monitor_touch` na linha inferior

## Recommended Approach

### 1) Config: secao [update] no config.ini (defaults em runtime)

Adicionar no `DEFAULT_INI` (`lib/config.lua`) e no `config.ini` do repo:
- `[update] enabled=true`
- `[update] ttl_hours=6`
- `[update] retry_seconds=120`
- `[update] error_backoff_max_seconds=900`

E no runtime, sempre ler via `state.cfg` com fallback para esses valores (assim installs antigos seguem funcionando mesmo sem secao).

### 2) Separar sucesso vs tentativa e introduzir backoff previsivel

Extender o estado/cache do update-check para carregar e persistir:
- `last_attempt_at_ms` (epoch utc ms) -> quando tentamos checar (sucesso ou erro)
- `last_success_at_ms` (epoch utc ms) -> quando obtivemos manifesto valido
- `fail_count` (int) -> quantidade de falhas consecutivas desde o ultimo sucesso (ou desde init)
- `next_retry_at_ms` (epoch utc ms) -> proxima tentativa permitida quando em erro/HTTP off

Compatibilidade:
- caches antigos nao tem esses campos -> normalizar para `nil/0` e continuar

Politica:
- Quando `enabled=false`: nao tentar HTTP; publicar status `disabled` e dormir longo
- Quando ultimo sucesso existir e `now - last_success_at_ms < ttl_ms`: nao tentar; dormir ate expirar
- Quando estiver em erro/HTTP off/bloqueado:
  - se `now < next_retry_at_ms`: dormir ate la (min 1s)
  - se `now >= next_retry_at_ms`: tentar novamente
  - em cada falha: `fail_count += 1`, calcular `delay = min(retry_seconds * 2^(fail_count-1), error_backoff_max_seconds)` e setar `next_retry_at_ms = now + delay*1000`
  - manter `available_version` conhecido e `stale=true` quando existir (D-04)
- Em sucesso: zerar `fail_count`, limpar `err`, `stale=false`, setar `last_success_at_ms=now`, e calcular proxima checagem pelo TTL

### 3) Expor detalhes no Monitor 2 sem poluir a UI principal

Adicionar uma view dedicada (ex.: `statusView == "update"`) acessivel por toque no Monitor 2.

Detalhes a mostrar (ASCII-only):
- installed
- available
- status
- stale
- last_checked (usar `last_attempt_at_ms`)
- last_success
- last_err
- manifest_url (truncada)

O header e o banner principal continuam discretos (nao criar novas linhas permanentes na view `main` alem de um "botao" curto no rodape).

### 4) Logs: evitar spam, mas registrar tentativas

O Scheduler ja loga por mudanca de status. Para cumprir D-07 ("INFO em mudanca de status ou quando ocorrer uma tentativa apos expiracao"), registrar tambem quando uma tentativa ocorre, mesmo que status permaneça igual.

Uma forma simples: incluir `last_attempt_at_ms` (ou um bucket derivado) na chave que decide logar, e limitar a logar apenas quando `did_attempt=true`.

## Risks / Pitfalls

- **Backoff infinito / nao previsivel:** sempre limitar por `error_backoff_max_seconds` e manter base em `retry_seconds`.
- **Cache corrompido:** normalizar de forma defensiva (sem quebrar UI/loops).
- **UI em monitores pequenos:** truncar URL/erros e manter layout com linhas fixas.
- **ASCII-only:** todas strings exibidas em UI devem evitar acentos/caracteres especiais.

## Validation Architecture

### Automated

- Comando: `startup test`
- Alvos:
  - `modules/update_check.lua`:
    - normalizacao de cache com novos campos
    - calculo de TTL vs retry/backoff (delay e cap)
    - comportamento quando `enabled=false`
  - `components/ui.lua`:
    - renderizacao/formatting de strings (pelo menos funcoes helper puras, se extraidas)

### Manual (in-world)

- Casos do checklist da fase (desabilitar, simular HTTP off, abrir tela de detalhes no Monitor 2).

---
*Phase: 13-operabilidade-update-check-config-backoff-detalhes*
