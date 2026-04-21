# Phase 15: Operabilidade + Resiliencia (doctor + persistencia + circuit breaker) - Research

**Created:** 2026-04-19
**Status:** Ready for planning

## Summary

Esta fase adiciona 3 capacidades operacionais sem alterar as regras de negocio do fluxo (equivalencias/tier/craft/entrega), focando em:
- `startup doctor`: diagnostico rapido, offline-first, com saida curta e acionavel.
- Persistencia leve de jobs: restaurar `state.work` apos reboot para evitar duplicar crafts e perder contexto.
- Circuit breaker/backoff do ME: reduzir spam de chamadas quando o grid oscila/offline e expor estado para UI/log.

Arquitetura atual relevante:
- `startup.lua` ja possui dispatch de modos via `shell.run("tests/run.lua")`, `shell.run("modules/*_cli.lua")` e fallback para `lib.bootstrap`.
- `lib.bootstrap` constroi `state` (cfg/logger/cache/devices/stats/work) e inicia `modules.scheduler`.
- `modules.engine` eh o "source of truth" do `state.work` e do loop de processamento.
- `modules.me` eh um wrapper do meBridge com cache TTL e `isOnline()` usado no engine.

## startup doctor (D-01, D-02)

Abordagem recomendada:
- Manter o dispatch no `startup.lua` consistente com os modos existentes: adicionar `doctor` chamando `shell.run("modules/doctor.lua")`.
- Implementar `modules/doctor.lua` como um script executavel (nao apenas um modulo) para reduzir dependencia de bootstrap e permitir rodar mesmo quando algo falha no init.

Checks sugeridos (todos via `pcall`/safe):
- HTTP:
  - Se `http` nao existe -> OFF
  - Se `http.checkURL` existe -> tentar `http.checkURL(url)` para `state.update.manifest_url` (ou URL fixa do manifest) e classificar como OK/BLOCKED
- Perifericos:
  - Checar `peripheral.isPresent(name)` para os nomes do `config.ini` em `[peripherals]`
  - Exibir colonyIntegrator, meBridge, modem, monitor_requests, monitor_status como present/absent
- ME:
  - Se meBridge presente, usar wrapper `modules.me` ou chamada direta `isConnected/isOnline` (sempre safe) para resumir Online/Offline
- Config:
  - Carregar `config.ini` via `lib.config` (com ensureDefaults)
  - Validar via `lib.config_schema.validateUpdates(cfg.data)` para enums/numeros e regra de monitores diferentes
- Saida:
  - Manter saida curta, em ASCII (sem acentos) para compatibilidade
  - Listar acoes sugeridas por problema encontrado (ex.: "Ajuste [peripherals] me_bridge=...", "Habilite HTTP no servidor", "Verifique nome do modem")

Pitfalls:
- Nao depender de `lib.bootstrap` (doctor deve rodar mesmo se bootstrap quebrar).
- Evitar log pesado no doctor; preferir `print()` curto.
- Garantir que o doctor nao altere estado do sistema alem de criar defaults de config (se ausente).

## Persistencia de jobs (D-03, D-04, D-05)

Objetivo: persistir somente o minimo para retomar contexto e evitar duplicacao de crafts.

Formato recomendado de `data/state.json` (schema v1):
- `v`: 1
- `saved_at_ms`: epoch utc
- `jobs`: tabela por request id (string), com campos:
  - `request_id` (redundante, opcional)
  - `chosen`
  - `status`
  - `missing`
  - `started_at_ms`
  - `retry_at_ms`
  - `last_err`

Implementacao:
- Criar um modulo pequeno (ex.: `modules/persistence.lua`) com:
  - `loadJobs(path)` -> retorna jobs ou nil
  - `saveJobs(path, jobs)` -> usa `Util.writeFileAtomic`
  - `compactEncode(tbl)` -> usar `textutils.serializeJSON(tbl)` sem pretty (compactacao simples)
- Integracao no engine:
  - No `Engine.new(state)` (ou inicio do `Engine:tick()` com um guard), tentar carregar `data/state.json` e aplicar em `self.work` somente para keys validas (string id)
  - Implementar saneamento:
    - expirar jobs antigos (ex.: se `saved_at_ms` ou `started_at_ms` for mais antigo que X horas)
    - limpar estados terminais (`done`) antigos
  - Salvamento:
    - salvar a cada N segundos (ex.: 2-5s) OU quando `work` mudar (hash simples / dirty flag)
    - garantir que `data/` exista antes de salvar (via `Util.ensureDir("data")`)

Pitfalls:
- `state.work` pode conter campos grandes; persistir apenas o subset definido em D-03.
- Evitar salvar em todo tick sem throttling (impacto de IO).
- Garantir escrita atomica para evitar arquivo corrompido em reboot.

## Circuit breaker / backoff ME (D-06, D-07)

Situacao atual:
- O engine chama `self.me:isOnline()` antes de consultas/craft/export.
- Quando offline, agenda retry curto (5s) e loga warn.

Abordagem recomendada:
- Implementar circuit breaker no wrapper `modules/me.lua`, evitando calls repetidas ao peripheral quando instavel:
  - Manter contadores em `state.health` (ex.: `state.health.me_fail_count`, `state.health.me_degraded`, `state.health.next_me_retry_at_ms`)
  - Quando `isOnline()` falhar:
    - incrementar `fail_count`
    - entrar em degraded por 30-120s (exponencial com teto): 30s, 60s, 120s
    - setar `next_me_retry_at_ms = now + delay`
  - Enquanto `me_degraded == true` e `now < next_me_retry_at_ms`:
    - `isOnline()` retorna `false, "degraded"` sem tocar no peripheral
    - `getItem/listItems/isCraftable/isCrafting/craftItem/exportItem` devem short-circuit com erro padrao `me_degraded`
- Expor estado para UI/log:
  - O engine ja mantem `state.health.peripherals`; adicionar chaves do ME em `state.health` para UI/observabilidade.

Pitfalls:
- Nao esconder erros reais: ao atingir `next_me_retry_at_ms`, tentar novamente; se recuperar, resetar fail_count e degraded.
- Evitar spam de logs: logar transicoes (enter degraded / exit degraded) e nao cada tick.

## Validation Architecture

O projeto valida via `startup test` (harness em `tests/run.lua`) e verificacoes in-world.

Nesta fase, os comportamentos principais sao em parte manuais (reboot/ME offline), mas partes de persistencia e circuit breaker podem ter testes unitarios com mocks de `fs`/`meBridge`.

Recomendacao:
- Adicionar testes unitarios para:
  - encode/decode de `data/state.json` (schema v1) e escrita atomica (usando mock de `fs`)
  - circuit breaker: dado N falhas, `isOnline` entra em degraded e respeita `next_me_retry_at_ms`
- Manter os testes seguindo o padrao existente: `require` antes de mockar `fs/peripheral`.
