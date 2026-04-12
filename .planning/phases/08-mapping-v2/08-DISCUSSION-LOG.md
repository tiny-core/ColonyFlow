# Phase 08: Mapping v2 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 08-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 08-mapping-v2
**Areas discussed:** Modelo do mapping, Prioridade, Fluxo da UI, Migração v1→v2

---

## Fonte de dados (JSON vs INI)

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| JSON como fonte de verdade | `data/mappings.json` permanece como banco principal; editor grava JSON v2 | ✓ |
| INI como fonte de verdade | banco migraria para um `.ini` | |
| INI só como export/import | banco permanece em JSON, INI é só conveniência | |

**User's choice:** Continuar com JSON.
**Notes:** INI foi considerado, mas a decisão final foi manter JSON.

---

## Modelo do mapping (como representar equivalência)

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| Classificação por tipo | item/tag vira uma regra com categoria/subtipo; equivalência é derivada por classe/tier | ✓ |
| Link item↔item | manter par/lista explícita de equivalentes como núcleo | |
| Híbrido | classificação base + links explícitos opcionais | |

**User's choice:** Classificação por tipo.
**Notes:** Foco em simplificação do editor.

---

## Entrada do seletor (ID vs tag)

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| ID + tag (#) | aceitar `mod:item` e tags `#namespace:tag/path` | ✓ |
| Só ID | apenas `mod:item` | |
| Só tag | tudo como tag | |

**User's choice:** ID + tag (#).
**Notes:** Tags entram com prefixo `#`.

---

## Prioridade (`prefer_equivalent`)

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| Só vanilla vs equivalente | decide vanilla-first vs preferir equivalente quando ambos são viáveis | ✓ |
| Ordem entre todos | define ordenação geral entre todos candidatos | |
| Só sugestão/UI | não altera escolha, só exibição | |

**User's choice:** Só vanilla vs equivalente.
**Notes:** Default definido como `false` (vanilla-first).

---

## Default do `prefer_equivalent`

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| false (vanilla-first) | comportamento seguro e previsível | ✓ |
| true (mod-first) | equivalente/mod primeiro | |
| Global config | default vem do `config.ini` | |

**User's choice:** false (vanilla-first).

---

## Fluxo do editor (operações)

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| Adicionar/Editar/Remover | CRUD completo com busca/listagem | ✓ |
| Só adicionar | apenas criar regras | |
| Adicionar + remover | cria e remove, sem edição | |

**User's choice:** CRUD completo.

---

## Navegação por teclado

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| Backspace para voltar | voltar/cancelar via Backspace | |
| Esc para voltar | voltar/cancelar via Esc | |
| Setas como primário | usar setas (incluindo esquerda/direita) para voltar/avançar + Enter para confirmar | ✓ |

**User's choice:** Setas (incluindo esquerda/direita) como base; Enter confirma.
**Notes:** Contrato final: ↑/↓ navega listas; Enter confirma; ← volta/cancela; → avança/confirmar quando fizer sentido.

---

## Tier override no editor

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| Só equivalência + prioridade | editor simplificado não mexe em tier | |
| Incluir tier override | editor também permite definir override de tier | ✓ |
| Incluir tudo | editor cobre também gating e demais estruturas | |

**User's choice:** Incluir tier override.

---

## Migração v1 → v2

| Opção | Descrição | Selecionado |
|------|-----------|-------------|
| Migrar em memória | converter para v2 internamente, sem reescrever arquivo | ✓ |
| Migrar e salvar | reescrever automaticamente para v2 | |
| Pedir confirmação | salvar só se o usuário confirmar | |

**User's choice:** Migrar em memória.

---

## Claude's Discretion

- Layout final das telas do editor (mantendo consistência com a UI atual).
- Mensagens de validação e UX do salvamento seguro.

## Deferred Ideas

Nenhuma.

