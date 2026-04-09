# Phase 04: UI + Configuração Operacional - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-09T18:52:00Z
**Phase:** 04-UI + Configuração Operacional
**Areas discussed:** Paginação/controles, Layout Monitor 1, Layout Monitor 2, Editor mapeamentos

---

## Paginação/controles

| Option | Description | Selected |
|--------|-------------|----------|
| Toque + auto | Botões por toque (←/→) e fallback de rotação automática se ninguém tocar. | ✓ |
| Só toque | Navegação apenas por toque; sem rotação automática. | |
| Só auto | Rotação automática de páginas; sem interação por toque. | |

**User's choice:** Toque + auto
**Notes:** Operação hands-off, mas com controle quando necessário.

| Option | Description | Selected |
|--------|-------------|----------|
| Auto por altura | Calcula pageSize pelo tamanho do monitor (linhas úteis) e preenche a tela. | ✓ |
| Fixo (N) | Usa um N fixo de linhas por página (config). | |
| Scroll/offset | Navega por offset de linhas (como scroll), em vez de páginas. | |

**User's choice:** Auto por altura

| Option | Description | Selected |
|--------|-------------|----------|
| Snapshot + diff | Renderiza só quando snapshot mudar, com limite mínimo/máximo de refresh. | ✓ |
| Intervalo fixo | Redesenha a cada X segundos, sempre. | |
| Sempre no tick | Redesenha todo tick do loop (mais simples, mas pode flickar). | |

**User's choice:** Snapshot + diff

| Option | Description | Selected |
|--------|-------------|----------|
| Sim (atalhos) | Teclas para trocar página/filtrar/pausar rotação. | ✓ |
| Não | Somente toque no monitor. | |
| Só terminal | Sem toque; controlar tudo no terminal. | |

**User's choice:** Sim (atalhos)

---

## Layout Monitor 1

| Option | Description | Selected |
|--------|-------------|----------|
| Status → faltante | Agrupa por status e dentro ordena por faltante desc. | ✓ |
| Somente faltante | Ordena só por faltante (maior primeiro). | |
| Por destino | Agrupa/ordena por target (building/worker). | |

**User's choice:** Status → faltante

| Option | Description | Selected |
|--------|-------------|----------|
| Padrão | Uma linha por request com colunas essenciais. | ✓ |
| Compacto | Mais curto para caber mais linhas. | |
| Detalhado | Mais colunas (tier, motivo, next_retry), pode exigir monitor maior. | |

**User's choice:** Padrão

| Option | Description | Selected |
|--------|-------------|----------|
| Marcador + cor | REQ→ESC com marcador de mudança e cor/flag para substituição vs sugestão. | ✓ |
| Duas linhas | Pedido numa linha e escolhido/ação na linha abaixo. | |
| Coluna extra | Coluna pequena SUB/SUG/OK sem depender de cores. | |

**User's choice:** Marcador + cor

| Option | Description | Selected |
|--------|-------------|----------|
| Sim (status) | Toggle para mostrar só pendentes, só erros/blocked etc. | ✓ |
| Não | Sempre mostra tudo. | |
| Sim (target) | Filtro por destino/building/worker. | |

**User's choice:** Sim (status)

---

## Layout Monitor 2

| Option | Description | Selected |
|--------|-------------|----------|
| 3 blocos | Colônia \| Operação \| Estoque crítico. | ✓ |
| Lista única | Uma lista contínua de métricas. | |
| Dashboard | Mais visual (barras/indicadores). | |

**User's choice:** 3 blocos

| Option | Description | Selected |
|--------|-------------|----------|
| Como hoje | Nome, cidadãos, felicidade, underAttack, obras. | ✓ |
| + prédios | Também contagem de prédios por nível/tipo. | |
| Só alertas | Mostrar apenas itens fora do normal. | |

**User's choice:** Como hoje

| Option | Description | Selected |
|--------|-------------|----------|
| Lista + threshold | Lista configurável com threshold mínimo por item. | |
| Auto por heurística | Detectar críticos automaticamente. | ✓ |
| Só manual (top N) | Mostrar apenas itens recentes com falha/retry. | |

**User's choice:** Auto por heurística

| Option | Description | Selected |
|--------|-------------|----------|
| Banner + cor | Linha(s) no topo com cor + contadores. | ✓ |
| Só contadores | Apenas números por tipo de erro. | |
| Tela alternada | Alternar entre status e tela só de alertas. | |

**User's choice:** Banner + cor

---

## Editor mapeamentos

| Option | Description | Selected |
|--------|-------------|----------|
| Menu (TUI) | Menu de opções com busca e formulários simples. | ✓ |
| Comandos | Comandos `map add/link/set-tier` etc. | |
| Wizard | Perguntas sequenciais sem menus. | |

**User's choice:** Menu (TUI)

| Option | Description | Selected |
|--------|-------------|----------|
| Equivalências | Link/unlink entre itens A↔B e listar vizinhos. | ✓ |
| Classe/tier | Definir/editar `class` e `tier` por item. | ✓ |
| Tier override | Overrides explícitos de tier. | ✓ |
| Allowlist | Marcar item/mod como permitido/não permitido. | ✓ |

**User's choice:** Equivalências, Classe/tier, Tier override, Allowlist

| Option | Description | Selected |
|--------|-------------|----------|
| Salvar seguro | Validar JSON + backup + preview de diff. | ✓ |
| Salvar direto | Escrever imediatamente a cada mudança. | |
| Exportar patch | Gerar patch/bloco de texto para aceitar manualmente. | |

**User's choice:** Salvar seguro

| Option | Description | Selected |
|--------|-------------|----------|
| Próximo ciclo | Recarregar `data/mappings.json` no próximo tick/ciclo automaticamente. | ✓ |
| Comando reload | Exigir comando/botão para aplicar mudanças. | |
| Só reiniciando | Aplicar só após reiniciar o programa. | |

**User's choice:** Próximo ciclo

---

## Claude's Discretion

- Definir atalhos de teclado e detalhes do mapeamento de prioridade de status para ordenação.
- Definir heurística de “estoque crítico” mantendo rastreabilidade via UI/log e configurabilidade quando necessário.

## Deferred Ideas

None
