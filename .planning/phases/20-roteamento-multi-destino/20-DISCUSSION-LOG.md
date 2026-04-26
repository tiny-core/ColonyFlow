# Phase 20: Roteamento Multi-Destino - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 20-roteamento-multi-destino
**Areas discussed:** Fallback em lista por classe, Cache/snapshot por destino, Config CLI menu estatico vs. editor, Health display com multiplos destinos

---

## Fallback em lista por classe

| Option | Description | Selected |
|--------|-------------|----------|
| Lista com fallback | armor_helmet=rack1,rack2 — consistente com default_target_container | |
| Periferico unico por classe | armor_helmet=rack1 — simples; se offline, cai no default direto | ✓ |

**User's choice:** Periferico unico por classe
**Notes:** Preferencia por simplicidade. Fallback e sempre o default_target_container, sem lista intermediaria.

---

## Cache/snapshot por destino

| Option | Description | Selected |
|--------|-------------|----------|
| Cache por nome (Recomendado) | Reutilizar state.cache com targetName como chave — zero mudanca de API | ✓ |
| Sem snapshot em routed | So tira snapshot do default; destinos roteados entregam direto sem pre-check | |

**User's choice:** Cache por nome
**Notes:** Aproveitar estrutura existente sem modificacao.

---

## Config CLI: menu estatico vs. editor

| Option | Description | Selected |
|--------|-------------|----------|
| Menu estatico com 11 classes | Lista as 11 classes fixas com valor atual, usuario escolhe qual editar | ✓ |
| Editor generico chave-valor | Usuario digita classe + periferico; flexivel mas sujeito a typo | |

**User's choice:** Menu estatico com 11 classes
**Notes:** Mais claro e menos propenso a erro. Classes sao fixas e conhecidas.

---

## Health display com multiplos destinos

| Option | Description | Selected |
|--------|-------------|----------|
| So default_target | Mantem como esta, destinos roteados offline visiveis no log | |
| Resumo X/Y targets online | Ex: "Targets: 3/4 online" — inclui default + roteados configurados | ✓ |
| Listar cada target separado | Linha por target — mais detalhado, ocupa mais espaco no monitor | |

**User's choice:** Resumo X/Y targets online
**Notes:** Visibilidade agregada sem ocupar espaco excessivo no monitor.

---

## Claude's Discretion

Nenhuma area delegada ao Claude nesta discussao — todas as decisoes foram tomadas pelo usuario.

## Deferred Ideas

- **UI de update discreta:** Exibir versao instalada e disponivel como `v1.5.0 -> v1.6.0` com cores
  diferentes, posicionado no header do monitor (substitui linha gigante atual). Phase 25 ou nova fase.
