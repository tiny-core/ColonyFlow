# MineColonies ME Automation

## What This Is

Sistema de automação em Lua para um Advanced Computer do CC: Tweaked que conecta MineColonies, Applied Energistics 2 e Advanced Peripherals. O objetivo é observar requisições pendentes da colônia, validar disponibilidade e necessidade real de itens, acionar autocrafting apenas do faltante e entregar automaticamente ao destino correto. A operação deve ser visível em dois Advanced Monitors com interface ASCII em tempo real e ser robusta o suficiente para rodar continuamente.

## Core Value

Fechar de forma confiável e autônoma o ciclo completo entre pedido do MineColonies e entrega do item correto, craftando somente o necessário.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Monitorar automaticamente requisições pendentes de NPCs e construções do MineColonies
- [ ] Consultar o sistema ME via Advanced Peripherals para verificar disponibilidade de itens
- [ ] Validar o conteúdo do baú ou inventário de destino antes de solicitar novos crafts
- [ ] Calcular apenas o faltante real antes de solicitar autocrafting
- [ ] Solicitar crafting automaticamente no AE2 e acompanhar o andamento da operação
- [ ] Entregar automaticamente os itens ao destino quando o inventário estiver conectado e identificável
- [ ] Exibir requisições e status operacional em dois Advanced Monitors com layout ASCII responsivo
- [ ] Registrar logs estruturados em português com rotação e níveis de severidade
- [ ] Operar em loop autônomo com fila, retentativas e recuperação segura de falhas

### Out of Scope

- Interface fora do jogo ou painel web — a v1 deve operar inteiramente dentro do ecossistema CC: Tweaked
- Matching avançado por NBT completo — a primeira versão usará correspondência por nome técnico e dano
- Dependência de intervenção manual no fluxo principal — a v1 prioriza operação autônoma

## Context

- O sistema será executado em um Advanced Computer do CC: Tweaked, usando Lua e convenções nativas do ambiente CraftOS.
- O mundo deve disponibilizar um conjunto completo de periféricos: integração com MineColonies, ponte ME/AE2 via Advanced Peripherals, inventários de destino identificáveis, dois Advanced Monitors e modem de rede.
- MineColonies trabalha com pedidos de itens feitos por trabalhadores e edifícios, o que torna essencial uma camada de orquestração para reduzir faltas, crafting desnecessário e retrabalho logístico.
- CC: Tweaked oferece a base de automação, periféricos, rede, paralelismo e interface em terminal/monitor para sustentar uma arquitetura modular orientada a serviços.
- Advanced Peripherals amplia a integração do computador com o sistema Applied Energistics 2, permitindo consulta de estoque e solicitação de autocrafting.
- A interface operacional deve ser separada em dois painéis: um monitor voltado à fila de requisições e outro a uma visão mista da colônia, operação e estoque crítico.
- O sistema precisa ser extensível, com raiz enxuta contendo apenas `startup.lua` e `config.ini`, e módulos auxiliares organizados em diretórios funcionais.

## Constraints

- **Ambiente**: Executar dentro de CC: Tweaked em Advanced Computer — o código deve respeitar APIs e limitações do CraftOS
- **Integração**: Depender de MineColonies, Applied Energistics 2 e Advanced Peripherals — a solução deve tratar ausência, indisponibilidade ou erro de periféricos
- **Operação**: Rodar de forma autônoma por longos períodos — confiabilidade e recuperação de falhas são prioridades de arquitetura
- **Observabilidade**: Logs e telas precisam ser claros em português — o operador deve conseguir diagnosticar problemas sem inspecionar código
- **Performance**: Atualizações em tempo real sem sobrecarregar o computador ou a rede de periféricos — polling, paginação e renderização devem ser eficientes
- **Estrutura**: Apenas `startup.lua` e `config.ini` na raiz — toda a lógica adicional deve ser modularizada em subpastas reutilizáveis

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Operação totalmente autônoma | O objetivo é reduzir intervenção manual e manter a colônia abastecida continuamente | — Pending |
| Entrega automática faz parte da v1 | O valor principal não termina no craft; precisa chegar ao destino correto | — Pending |
| Correspondência por nome técnico e dano | Entrega boa precisão com menor complexidade que matching por NBT completo na primeira versão | — Pending |
| Segundo monitor com painel misto | O operador precisa ver colônia, operação e estoque crítico sem trocar de tela | — Pending |
| Política de falha com alerta e fila | Requisições problemáticas devem permanecer visíveis e elegíveis para nova tentativa | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-05 after initialization*
