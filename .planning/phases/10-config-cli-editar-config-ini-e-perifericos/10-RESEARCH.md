# Phase 10: Config CLI (editar config.ini e perifericos) - Research

## Summary

Esta fase adiciona um novo CLI no terminal para editar `config.ini` com foco em:
- `[peripherals]` (nomes de perifericos e monitores)
- `[core]` + chaves de logs
- `[delivery]`

E precisa salvar sem destruir comentarios/ordem do arquivo atual, com validacao e escrita segura (tmp + move + backup).

## Codebase Map (relevante)

### config.ini / Config
- Parser e defaults: `lib/config.lua` (`parseIni`, `Config.load`, `Config.ensureDefaults`).
- Nao existe writer/patcher de INI (apenas parse).
- Coercao com fallback: `getNumber`, `getBool`, `getList`.

### Perifericos
- Descoberta central: `modules/peripherals.lua` (`discover` + `resolve`).
  - Resolve por nome configurado -> `peripheral.isPresent` + `wrap`.
  - Fallback por tipo -> `peripheral.find(type)` (para `me_bridge` aceita `"meBridge"` e `"me_bridge"`).
  - Em falha, loga hint e lista parcial de `peripheral.getNames()`.

### Call sites sensiveis a config de entrega
- `modules/engine.lua` resolve destino e buffer por nome vindo do INI:
  - `delivery.default_target_container` (lista, pega o primeiro presente).
  - `delivery.export_buffer_container` e `delivery.export_mode` (enum).
  - Erros de enum (ex.: `export_mode_invalido`) aparecem em runtime.

### Padrao de CLI/TUI existente
- `startup.lua` ja roteia `startup test` e `startup map` para scripts.
- `modules/mapping_cli.lua` define um padrao de TUI com `selectList(...)`:
  - Navegacao via `os.pullEvent()` + `keys`.
  - Cores opcionais via `term.isColor()`.
  - Persistencia de dados via `Util.readFile/writeFile` (JSON).

## Recommended Approach

### 1) Novo `modules/config_cli.lua`
- Reusar o padrao do `modules/mapping_cli.lua` (principalmente `selectList` e helpers de cor).
- Menu principal por blocos: Perifericos | Core+Logs | Delivery | Sair.
- Fluxo por bloco: editar -> testar (quando aplicavel) -> preview -> salvar.

### 2) Writer/patcher de INI (preservando comentarios)
Implementar um patcher que:
- Leia o arquivo como linhas (sem parse destrutivo).
- Localize secao alvo (`[peripherals]`, `[core]`, `[delivery]`).
- Para cada chave:
  - Se existir uma linha `key=...` na secao: substituir apenas o valor.
  - Se nao existir: inserir `key=value` no final da secao (antes da proxima secao).
- Preservar:
  - Comentarios e linhas desconhecidas.
  - Ordem existente das chaves nao editadas.
- Escrever de forma segura:
  - Criar backup em `data/backups/` sempre antes de salvar.
  - Escrever `config.ini.tmp` e so depois trocar para `config.ini` (via `fs.move`).

### 3) Validacao (bloqueante) no CLI
- Enums e ranges devem ser validados antes de salvar (bloquear e explicar):
  - `core.poll_interval_seconds` numero > 0
  - `core.ui_refresh_seconds` numero > 0
  - `core.log_level` em {DEBUG, INFO, WARN, ERROR}
  - `core.log_max_files` numero >= 1
  - `core.log_max_kb` numero >= 1
  - `delivery.export_mode` em {auto, peripheral, direction, buffer}
  - `delivery.export_direction` em {up, down, north, south, east, west}
  - `delivery.destination_cache_ttl_seconds` numero >= 0
- Perifericos:
  - Validar por `peripheral.isPresent` + `peripheral.wrap`.
  - Impedir `monitor_requests == monitor_status`.
  - Ajuda de selecao:
    - Mostrar lista de `peripheral.getNames()` quando pedido.
    - Auto-detect por tipo (sugere um candidato) e pedir confirmacao.

## Risks / Pitfalls

- Re-serializar INI via parseIni vai perder comentarios e ordem (config.ini atual e documentado).
- Escrita direta com `fs.open("w")` trunca o arquivo; se falhar no meio pode corromper.
- Rodar CLI enquanto o daemon esta em execucao pode gerar leitura parcial/estado hibrido.
  - Mitigacao: `startup config` deve ser um modo separado, nao rodar junto do loop.
- Validacao fraca de perifericos permite salvar nomes errados e o erro so aparece depois no engine/UI.

## Validation Architecture

### Objetivo de validacao
Garantir que:
1) `startup config` existe e abre o novo CLI
2) O CLI consegue ler `config.ini`, editar valores, mostrar preview e salvar preservando comentarios/linhas desconhecidas
3) A validacao de perifericos e valores bloqueia entradas invalidas e impede salvar quando necessario
4) Backups e escrita atomica evitam corromper o arquivo em falha

### Estrategia de testes (CC: Tweaked)
- Unit tests (harness existente):
  - Testar patcher do INI com fixtures (linhas com comentarios, secoes ausentes, chaves ausentes, chaves duplicadas).
  - Testar que chaves desconhecidas e comentarios sao preservados.
- Testes de validacao:
  - Validacao de enum (export_mode) e range (poll_interval_seconds).
  - Validacao de monitores duplicados.
- Testes de IO seguro:
  - Simular escrita em tmp + move e criacao de backup (mock de `fs`).

### Verificacoes manuais (in-world)
- Rodar `startup config` e navegar pelo menu.
- Ajustar um valor simples (ex.: log_level) e confirmar que comentarios do arquivo continuam.
- Forcar erro (ex.: export_mode invalido) e confirmar que nao salva e que a mensagem explica.

---

*Phase: 10-config-cli-editar-config-ini-e-perifericos*
