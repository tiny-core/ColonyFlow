---
phase: 09-instalador-git
plan: 01
subsystem: infra
tags: [http, installer, cc-tweaked, rollback, manifest]

requires:
  - phase: 08-mapping-v2
    provides: Base do sistema (startup + módulos) para instalar/atualizar
provides:
  - Instalador standalone em `tools/install.lua` (doctor/install/update)
  - Manifesto remoto `manifest.json` com escopo de arquivos gerenciados/preservados
affects: [setup, update, robustez, diagnóstico]

tech-stack:
  added: []
  patterns: [update em 2 fases, snapshot+rollback, preservação por padrão]

key-files:
  created: [tools/install.lua, manifest.json]
  modified: [.planning/phases/09-instalador-git/09-VERIFICATION.md]

key-decisions:
  - "Manter estado instalado em data/version.json (managed_files) para remoção segura de órfãos"
  - "Preservar por padrão config.ini, data/mappings.json, data/install.json e data/version.json"

patterns-established:
  - "Atualização segura: download/validação -> snapshot -> apply -> (opcional) delete órfãos -> persistir versão; rollback automático em falha"

requirements-completed: [CFG-01, ROB-01]

duration: 2 min
completed: 2026-04-12
---

# Phase 09 Plan 01: Instalador/Atualizador via Git raw Summary

**Instalador in-world via HTTP com manifesto remoto, update em 2 fases, snapshot+rollback e preservação de config/dados por padrão**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-12T23:10:17+01:00
- **Completed:** 2026-04-12T23:11:38+01:00
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Manifesto remoto determinístico (`manifest_version`, `generated_utc`, `files[]`) definindo o escopo de arquivos gerenciados/preservados
- Instalador standalone `tools/install.lua` com `doctor/install/update`, validação de manifesto, download em temporário, snapshot e rollback automático
- Checklist de verificação manual da fase atualizado para cobrir bootstrap, preservação, erros acionáveis e rollback

## Task Commits

Each task was committed atomically:

1. **Task 1: Definir manifesto remoto e política de arquivos gerenciados/preservados** - `95d0d4d` (feat)
2. **Task 2: Implementar tools/install.lua (doctor/install/update) com update seguro e rollback** - `f527833` (feat)
3. **Task 3: Atualizar checklist de verificação da Fase 09** - `c9392dc` (docs)

## Files Created/Modified
- manifest.json - Lista de arquivos gerenciados e flags de preservação
- tools/install.lua - Instalador/atualizador via HTTP com temp/snapshot/rollback
- .planning/phases/09-instalador-git/09-VERIFICATION.md - Checklist manual guiado (bootstrap/update/doctor/rollback)

## Decisions Made
- None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Checklist manual pronto em 09-VERIFICATION.md para validar bootstrap em computador limpo, preservação no update e erro acionável quando HTTP estiver desabilitado.

---
*Phase: 09-instalador-git*
*Completed: 2026-04-12*
