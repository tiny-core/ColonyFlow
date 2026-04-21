# Summary

ColonyFlow é um sistema autônomo em Lua (CC: Tweaked) que fecha o ciclo completo entre **pedido do MineColonies** e **entrega do item correto**, usando **AE2 (ME Bridge via Advanced Peripherals)** para estoque, craft e exportação.

## Core value

- Craftar somente o necessário (faltante real) e entregar no destino correto, com observabilidade (UI + logs) para operar sem abrir o código.

## Stack (alto nivel)

- **CC: Tweaked**: runtime, filesystem, eventos, term/monitor, rede de periféricos
- **Advanced Peripherals**: `colonyIntegrator` (MineColonies) e `meBridge` (AE2)
- **AE2**: estoque, craftabilidade, jobs de crafting, exportação
- **MineColonies**: fonte de demanda (requests, buildings/workers)

## Fluxo principal (1 minuto)

1. Coletar requests do MineColonies e normalizar para um modelo interno
2. Resolver candidatos (equivalências entre mods + tiers) respeitando progressão
3. Inspecionar destino e calcular faltante real (não craftar cegamente)
4. Consultar ME (estoque/craftavel) e abrir craft apenas do faltante
5. Exportar itens ao destino e atualizar estado
6. Renderizar snapshots na UI e registrar logs estruturados

## Princípios que guiam o código

- **Estado explícito + retries**: evita craft duplicado e falhas silenciosas
- **Snapshot para UI**: UI não faz IO de periféricos; apenas renderiza
- **Integrações isoladas**: MineColonies/ME/destinos em módulos dedicados
- **Operação primeiro**: logs e UI são parte do produto (diagnóstico claro)

## Onde começar a ler

- `docs/LEIA-ME-DO-CODIGO.md`
- `docs/ARCHITECTURE.md`
- `docs/PITFALLS.md`
