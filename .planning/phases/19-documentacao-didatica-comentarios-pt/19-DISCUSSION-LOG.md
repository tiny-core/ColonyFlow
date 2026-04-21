# Phase 19: documentacao-didatica-comentarios-pt - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 19-documentacao-didatica-comentarios-pt
**Areas discussed:** Estrutura de docs

---

## Estrutura de docs

### Onde o guia didatico principal deve viver no repo?

| Option | Description | Selected |
|--------|-------------|----------|
| docs/ | Criar `docs/LEIA-ME-DO-CODIGO.md` e linkar a partir do README | ✓ |
| Somente README.md | Colocar o guia direto no README (maior), evitando pasta nova | |
| .planning/research/ | Manter como documentacao mais interna e README apenas aponta para la | |

**User's choice:** docs/

---

### Como o README.md deve apontar para o guia?

| Option | Description | Selected |
|--------|-------------|----------|
| Secao 'Documentacao' | Adicionar uma secao no README com links para o guia e para docs tecnicos | ✓ |
| Topo do README | Um link bem no comeco do README | |
| So 1 link | Um unico link simples | |

**User's choice:** Secao 'Documentacao'

---

### Formato da documentacao didatica

| Option | Description | Selected |
|--------|-------------|----------|
| 1 arquivo | Um guia central com indice interno | |
| Varios capitulos | Varios MD em `docs/` + um indice | |
| Misto | Guia central + poucos docs de apoio | ✓ |

**User's choice:** Misto

---

### Quais docs extras expor junto do guia no README?

| Option | Description | Selected |
|--------|-------------|----------|
| Somente o guia | README aponta apenas para o guia | |
| Guia + Arquitetura | Linkar guia + doc de arquitetura/fluxo | |
| Guia + 3 docs | Linkar guia + arquitetura/fluxo + pitfalls/operacao + resumo | ✓ |

**User's choice:** Guia + 3 docs

---

### Origem dos 3 docs extras (README linka para onde?)

| Option | Description | Selected |
|--------|-------------|----------|
| Copiar p/ docs/ | README aponta para `docs/ARCHITECTURE.md`, `docs/PITFALLS.md`, `docs/SUMMARY.md` | ✓ |
| Linkar .planning/research | README aponta direto para `.planning/research/*` | |
| Misto | Misturar docs em `docs/` e `.planning/research/` | |

**User's choice:** Copiar p/ docs/

---

## Claude's Discretion

None recorded.

## Deferred Ideas

None recorded.

