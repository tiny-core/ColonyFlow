---
phase: 11-versionamento-robusto-versao-real-script-node-para-regenerar
plan: 01
subsystem: infra
tags: [semver, manifest, installer, node, cc-tweaked]

requires:
  - phase: 10-config-cli-editar-config-ini-e-perifericos
    provides: config e perifericos configuraveis (base para evolucoes de tooling)
provides:
  - Versao real (SemVer) canonica via arquivo VERSION
  - Manifesto gerado com lista ordenada e size por arquivo
  - Instalador valida manifest.version e persiste data/version.json com version
affects: [fase-12, update-check, instalador, manifest]

tech-stack:
  added: []
  patterns: [VERSION como fonte canonica, manifesto gerado por tooling deterministico]

key-files:
  created: [VERSION, tools/gen_manifest.js, lib/version.lua]
  modified: [manifest.json, tools/install.lua, tests/run.lua, README.md]

key-decisions:
  - "SemVer simples X.Y.Z (somente numeros, sem zeros a esquerda) como formato canonico do VERSION"

patterns-established:
  - "VERSION: arquivo raiz com SemVer canonico para refletir versao real do repo"
  - "tools/gen_manifest.js: geracao de manifest.json ordenado e com size para integridade basica"

requirements-completed: []

duration: 5 min
completed: 2026-04-14
---

# Phase 11 Plan 01: Versao real + gerador de manifesto - Summary

**Manifesto passa a carregar uma versao real (SemVer) e e regenerado por script Node com lista ordenada e size; instalador valida e persiste version em data/version.json.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-14T18:39:12Z
- **Completed:** 2026-04-14T18:44:41Z
- **Tasks:** 5
- **Files modified:** 8

## Accomplishments
- VERSION como fonte canonica de versao e manifest.json com campo version
- Instalador valida manifest.version, exibe versao e grava version/manifest_generated_utc em data/version.json
- Script Node gera manifest.json ordenado com size e preserve nos arquivos do usuario
- Helper lib/version.lua para validar e comparar SemVer, com testes dedicados
- Documentacao do fluxo de bump de versao + regeneracao de manifesto

## Task Commits

Each task was committed atomically:

1. **Task 1: Adicionar fonte canonica de versao (arquivo VERSION) e atualizar manifest.json para incluir version** - `159c685` (feat)
2. **Task 2: Atualizar instalador: validar version do manifesto e persistir version em data/version.json** - `4e2f6c6` (feat)
3. **Task 3: Adicionar lib/version.lua (validacao + compare SemVer) e testes** - `2f92c29` (feat)
4. **Task 4: Adicionar script Node tools/gen_manifest.js para regenerar manifest.json (ordenado + size + preserve)** - `eeca215` (feat)
5. **Task 5: Documentar fluxo de bump de versao + regeneracao de manifesto** - `80cfd99` (docs)

## Files Created/Modified
- VERSION - fonte canonica da versao real (SemVer)
- tools/gen_manifest.js - gera manifest.json ordenado com size e preserve
- manifest.json - inclui version + generated_utc e passa a conter size por arquivo
- tools/install.lua - valida version do manifesto, exibe e persiste em data/version.json
- lib/version.lua - helper para validar/ordenar SemVer e ler versao instalada
- tests/run.lua - testes semver_is_valid e semver_compare
- README.md - documenta o fluxo de bump de versao e regeneracao do manifesto

## Decisions Made
- None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Validacao in-world via `startup test` e `tools/install.lua update` ainda precisa ser executada manualmente no computador do jogo.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Versao instalada agora pode ser lida de data/version.json e comparada; fase 12 pode implementar update-check e exibir versao atual vs disponivel.

---
*Phase: 11-versionamento-robusto-versao-real-script-node-para-regenerar*
*Completed: 2026-04-14*
