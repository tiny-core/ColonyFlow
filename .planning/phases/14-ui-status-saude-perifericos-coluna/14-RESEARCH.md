# Phase 14: UI Status - Saude de perifericos (coluna alinhada) - Research

## Summary

A base da UI ja desenha o Monitor 2 com secoes COLONIA e OPERACAO, mas hoje a parte de operacao e uma lista linear (Requisicoes, Entregues, Crafts, Substituicoes, Erros). A fase 14 pede evoluir esse trecho para um layout em duas colunas alinhadas: contadores na esquerda e saude dos perifericos na direita.

Requisitos tecnicos chave:
- Status de ME Bridge precisa usar `ME:isOnline()` (estado real do grid), nao apenas "periferico presente".
- Resultado precisa usar cache/snapshot para evitar chamadas repetidas por frame de UI.
- Textos visiveis em monitor devem permanecer ASCII-only.

## Codebase Map (relevante)

- `components/ui.lua`
  - `renderStatus()` desenha OPERACAO em linhas simples e e o ponto certo para migrar para tabela de duas colunas.
  - `drawText()` ja evita redesenho desnecessario por buffer (bom para flicker/performance).
  - `shorten()` e `padRight()` podem ser reutilizados para truncamento/alinhamento.
- `modules/me.lua`
  - `ME:isOnline()` ja aplica verificacao robusta (`isConnected`/`isOnline`) com fallback.
- `modules/peripherals.lua`
  - `discover()` publica `state.devices` com `meBridge`, `colonyIntegrator`, `modem`, `monitorRequests`, `monitorStatus`.
- `modules/engine.lua`
  - `tick()` ja concentra snapshots operacionais (`state.requests`, `state.colonyStats`) e e o ponto correto para gerar `state.health`.
- `lib/cache.lua`
  - Cache TTL generico disponivel via `state.cache:get/set(namespace, key, value, ttlSeconds)`.

## Recommended Approach

### 1) Snapshot de saude em `engine.tick()` com TTL curto

Adicionar um snapshot `state.health.peripherals` atualizado por TTL (ex.: 2s), nao a cada render:
- `meBridge`: status derivado de `self.me:isOnline()`
- `colonyIntegrator`: presente/ausente por `state.devices.colonyIntegrator`
- `modem`: presente/ausente
- `monitorRequests`: presente/ausente
- `monitorStatus`: presente/ausente

Estrutura recomendada por entrada:
- `label` (ex.: `"ME Bridge"`)
- `value` (`"Online"`, `"Offline"`, `"NA"`)
- `level` (`"ok"`, `"bad"`, `"unknown"`)

Persistir no cache:
- namespace: `ui_health`
- key: `peripherals`
- ttl: 2 segundos

### 2) Render em duas colunas no `renderStatus()`

No bloco OPERACAO:
- Substituir as 5 linhas lineares por um conjunto de linhas pareadas:
  - coluna esquerda: contadores
  - coluna direita: perifericos
- Calcular `leftW` e `rightW` com separador fixo `" | "`.
- Aplicar `shorten()` em cada coluna para nao estourar largura de monitor pequeno.

Exemplo de linhas:
- Esquerda: `Requisicoes: 12` | Direita: `ME Bridge: Online`
- Esquerda: `Entregues: 54` | Direita: `Colony: Online`
- Esquerda: `Crafts: 18` | Direita: `Modem: Offline`

### 3) Cores por valor na coluna de perifericos

Cor apenas no valor da direita:
- `ok` -> `colors.lime`
- `bad` -> `colors.red`
- `unknown` -> `colors.gray`

Manter label em branco/ciano e evitar combinacoes de fg/bg que percam contraste.

### 4) Testabilidade sem depender de monitor real

Extrair helper puro de layout (string de linha em duas colunas) para teste unitario:
- entrada: `leftText`, `rightLabel`, `rightValue`, `width`
- saida: strings formatadas/truncadas + offsets usados

Cobrir em `tests/run.lua`:
- largura pequena
- alinhamento basico
- truncamento deterministico

## Risks / Pitfalls

- **Risco de spam de periferico:** chamar `ME:isOnline()` em cada frame pode aumentar custo de tick; mitigar com cache TTL no engine.
- **Risco de layout quebrado:** monitor estreito pode cortar conteudo; mitigar com truncamento e largura minima por coluna.
- **Risco de semantica errada no ME:** usar apenas presenca de `meBridge` mascara grid offline; mitigar usando `ME:isOnline()`.
- **Risco de regressao visual:** alterar y-offset pode empurrar rodape/botoes; validar manualmente em monitores com alturas diferentes.

## Validation Architecture

### Automated

- Comando rapido: `startup test`
- Alvos:
  - helper de formatacao/alinhamento da coluna dupla (novo ou extraido de `components/ui.lua`)
  - regra de mapeamento de cores por `level`
  - composicao de snapshot de saude com fallback para `NA`

### Manual (in-world)

- Confirmar coluna alinhada em Monitor 2 com perifericos online/offline.
- Simular ME offline/desconectado e validar `ME Bridge: Offline` em vermelho.
- Confirmar que UI permanece responsiva (sem flicker excessivo).

---
*Phase: 14-ui-status-saude-perifericos-coluna*
