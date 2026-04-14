# Phase 12: Update check leve no startup + mostrar versao atual vs disponivel na UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi
**Areas discussed:** Fonte + cache, Comportamento no boot, Como mostrar na UI, Mensagem/acao

---

## Fonte + cache

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest remoto | Ler manifest.json remoto (mesmo artefato do instalador) e comparar com data/version.json | ✓ |
| Arquivo version.txt | Adicionar um arquivo remoto pequeno so com a versao |  |
| So local | Mostrar apenas versao instalada (sem consulta remota) |  |

**User's choice:** Manifest remoto

| Option | Description | Selected |
|--------|-------------|----------|
| data/install.json | Usar a mesma config do instalador; defaults quando faltar campo | ✓ |
| Defaults fixos | Usar constantes no codigo |  |
| config.ini | Colocar base/ref/manifest em config.ini |  |

**User's choice:** data/install.json

| Option | Description | Selected |
|--------|-------------|----------|
| Boot + TTL | Checa no boot, mas respeita TTL salvo em cache persistido | ✓ |
| Todo boot | Sempre checa sem cache |  |
| Manual | So checa quando rodar comando |  |

**User's choice:** Boot + TTL

| Option | Description | Selected |
|--------|-------------|----------|
| 6 horas | Equilibrio entre atualizacao e chamadas HTTP | ✓ |
| 1 hora | Mais chamadas HTTP |  |
| 24 horas | Menos chamadas, aviso pode demorar |  |

**User's choice:** 6 horas

---

## Comportamento no boot

| Option | Description | Selected |
|--------|-------------|----------|
| Background | Nao atrasa o boot; roda em paralelo e atualiza UI quando terminar | ✓ |
| Sincrono curto | Roda antes do loop com tentativa unica |  |
| Sincrono completo | Roda antes do loop com retries; pode atrasar boot |  |

**User's choice:** Background

| Option | Description | Selected |
|--------|-------------|----------|
| Silencioso | Ignora o update-check sem mostrar nada |  |
| UI discreta | Indica na UI e segue; sem banner chamativo | ✓ |
| Banner/alerta | Banner no Monitor 2 |  |

**User's choice:** UI discreta

| Option | Description | Selected |
|--------|-------------|----------|
| 1 tentativa | Mais leve |  |
| 2 tentativas | Meio-termo com delay curto | ✓ |
| 3 tentativas | Mais resiliente, mais lento em rede ruim |  |

**User's choice:** 2 tentativas

| Option | Description | Selected |
|--------|-------------|----------|
| Manter ultimo | Mantem ultimo available conhecido (stale) ate conseguir checar de novo | ✓ |
| Limpar | Apaga available e mostra desconhecido |  |
| Somente local | Mostra apenas versao instalada |  |

**User's choice:** Manter ultimo

---

## Como mostrar na UI

| Option | Description | Selected |
|--------|-------------|----------|
| Topo + banner | Header (canto direito) + banner no Monitor 2 quando houver update | ✓ |
| So topo | Apenas header |  |
| So banner | Apenas banner |  |

**User's choice:** Topo + banner

| Option | Description | Selected |
|--------|-------------|----------|
| Hora + inst | Hora + versao instalada; se update: `inst->avail` | ✓ |
| So versao | So versao; sem hora |  |
| Marcador curto | Hora + inst + UPD (sem mostrar versao nova) |  |

**User's choice:** Hora + inst

| Option | Description | Selected |
|--------|-------------|----------|
| Versao + comando | Mostra versoes + comando sugerido | ✓ |
| So versoes | Mostra apenas as versoes |  |
| So comando | Mostra so o comando |  |

**User's choice:** Versao + comando

| Option | Description | Selected |
|--------|-------------|----------|
| Sem marcador | Atualizado: so hora+versao; indisponivel: indicar `UPD:OFF` | ✓ |
| Sempre status | Sempre mostrar `UPD:OK/NEW/OFF` |  |
| So quando NEW | So mostra extra quando tiver update; HTTP off fica silencioso |  |

**User's choice:** Sem marcador

---

## Mensagem/acao

| Option | Description | Selected |
|--------|-------------|----------|
| So UI + log | Sem print no terminal no boot | ✓ |
| UI + print | Imprime 1 linha no terminal no boot |  |
| So print | Sem UI dedicada |  |

**User's choice:** So UI + log

| Option | Description | Selected |
|--------|-------------|----------|
| INFO/INFO | Update disponivel = INFO; falhas/indisponivel = INFO | ✓ |
| INFO/WARN | Update disponivel = INFO; falhas/indisponivel = WARN |  |
| WARN/WARN | Tudo WARN |  |

**User's choice:** INFO/INFO

| Option | Description | Selected |
|--------|-------------|----------|
| tools/install.lua update | Comando de atualizar | ✓ |
| tools/install.lua doctor | Comando de diagnostico |  |
| Ambos | Update + doctor |  |

**User's choice:** tools/install.lua update

| Option | Description | Selected |
|--------|-------------|----------|
| Mostrar '-' | Mostra instalado como '-' |  |
| Sugerir install | Indica sem versao e sugere `tools/install.lua install` | ✓ |
| Tratar como dev | Mostra DEV |  |

**User's choice:** Sugerir install

---

## Claude's Discretion

- Formato do cache local do update-check e como marcar `stale` de forma discreta.
- Truncamento/abreviacao para caber no monitor sem quebrar layout.

## Deferred Ideas

None
