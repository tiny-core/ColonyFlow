# Phase 12: Update check leve no startup + mostrar versao atual vs disponivel na UI - Research

## Summary

Hoje a UI mostra um placeholder fixo (`VERSION = "v1"`) no header dos monitores, sem relacao com a versao real do projeto. A Fase 11 introduziu:
- `manifest.json` com `version` (SemVer `X.Y.Z`)
- `tools/install.lua` gravando `data/version.json` com `version`, `manifest_url`, `ref`, etc.
- `lib/version.lua` para ler `data/version.json` e comparar SemVer

Esta fase deve adicionar um update-check leve e nao-bloqueante que:
1) Le a versao instalada local (via `data/version.json`)
2) Descobre a URL do `manifest.json` remoto (derivada de `data/install.json`, com defaults)
3) Baixa o manifesto remoto em background (quando HTTP existir), valida `version` e compara com a instalada
4) Persiste resultado em cache com TTL (padrao 6 horas) e atualiza `state` para a UI renderizar

## Codebase Map (relevante)

### Versao local (instalada)
- `lib/version.lua`
  - `Version.readInstalled()` le `data/version.json` e retorna `{ version, ref, manifest_url }` ou `nil`
  - `Version.compare(a, b)` compara SemVer simples `X.Y.Z`

### Manifesto remoto (disponivel)
- `manifest.json` (repo) contem:
  - `manifest_version` (schema)
  - `version` (SemVer do projeto)
  - `files` (lista)
- `tools/install.lua`
  - Ja implementa HTTP GET com retry e valida manifesto remoto (inclui `version`)
  - Cria `data/install.json` (quando nao existe) e salva `manifest_path`
  - Usa defaults embutidos para `base_url` + `ref` + `manifest_path`

### Bootstrap / loops / UI
- `lib/bootstrap.lua` constroi `state`, `engine`, `ui` e inicia `modules/scheduler.lua`
- `modules/scheduler.lua` roda loops em paralelo (engine/ui/eventos)
- `components/ui.lua` renderiza os dois monitores e o header (hora + placeholder)

## Recommended Approach

### 1) Criar um update-check reutilizavel no runtime (nao em tools/)
- Introduzir um modulo (ex.: `modules/update_check.lua` ou `lib/update_check.lua`) responsavel por:
  - Ler `data/install.json` (quando existir) e montar `manifest_url` com defaults
  - Ler cache persistido (ex.: `data/update_check.json`) com `checked_at_ms`, `ttl_ms`, `available_version`, `status` e `err`
  - Decidir se deve checar agora (TTL expirou) ou manter o cache (fresh/stale)
  - Executar fetch remoto com 2 tentativas quando HTTP estiver disponivel
  - Validar resposta minima do manifesto (JSON + `version` SemVer)
  - Atualizar `state.update` e persistir cache

### 2) Rodar em background sem atrasar boot
- Adicionar um loop dedicado no `Scheduler` para update-check:
  - No inicio: carregar cache e publicar em `state.update` (para a UI ter algo imediato)
  - Em seguida: se TTL expirou, checar remoto; senao, dormir ate expirar (ou dormir curto e reavaliar)
  - Sempre proteger com `pcall` e backoff simples em erro

### 3) Exibir na UI de forma discreta
- Header (canto direito) nos dois monitores:
  - Base: `HH:MM:SSZ <instalada>`
  - Se update disponivel: `HH:MM:SSZ <instalada>-><disponivel>`
  - Se HTTP indisponivel/bloqueado: adicionar um indicador curto: `UPD:OFF`
  - Se versao instalada ausente: indicar e sugerir install no Monitor 2 (Status)
- Monitor 2 (Status): quando houver update, mostrar uma linha/banner com versoes + comando sugerido:
  - `Update: <instalada> -> <disponivel>  Run: tools/install.lua update`

## Risks / Pitfalls

- **Boot bloqueado por rede:** update-check nao pode rodar sincrono; sempre em background e com timeout/retry limitado.
- **HTTP API ausente:** em alguns mundos/servidores `http` pode estar desabilitado; deve cair para `UPD:OFF` e seguir.
- **Manifesto invalido:** JSON malformado ou `version` ausente/errada; tratar como erro recuperavel e manter ultimo `available` conhecido (stale).
- **Layout apertado:** headers precisam truncar para caber em monitores pequenos sem quebrar alinhamento/tabelas.
- **Mensagens in-game:** UI/logs devem ser ASCII (sem acentos) para evitar glifos quebrados no CC.

---
*Phase: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi*
