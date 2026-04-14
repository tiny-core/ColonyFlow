# Phase 11 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (offline + in-world)

1. Offline (repo):
   - Rodar `node tools/gen_manifest.js 0.11.0` (ou a versao desejada)
   - Confirmar que `manifest.json` contem:
     - `"manifest_version": 2`
     - `"version": "X.Y.Z"`
     - `"generated_utc": "....Z"`
     - `size` presente em todas entradas de `files`
     - `config.ini` e `data/mappings.json` marcados com `"preserve": true`
2. In-world (computer):
   - Rodar `tools/install.lua update`
   - Confirmar que `data/version.json` contem o campo `version` e que bate com o `manifest.json` remoto
3. Sanidade do instalador:
   - Confirmar que mensagens novas do instalador sao ASCII (sem acentos)

## Resultado

- [ ] Automated OK
- [ ] Manual OK
