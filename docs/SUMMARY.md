# Summary

ColonyFlow e um sistema autonomo em Lua (CC: Tweaked) que fecha o ciclo completo entre **pedido do MineColonies** e **entrega do item correto**, usando **AE2 (ME Bridge via Advanced Peripherals)** para estoque, craft e exportacao.

## Core value

- Craftar somente o necessario (faltante real) e entregar no destino correto, com observabilidade (UI + logs) para operar sem abrir o codigo.

## Stack (alto nivel)

- **CC: Tweaked**: runtime, filesystem, eventos, term/monitor, rede de perifericos
- **Advanced Peripherals**: `colonyIntegrator` (MineColonies) e `meBridge` (AE2)
- **AE2**: estoque, craftabilidade, jobs de crafting, exportacao
- **MineColonies**: fonte de demanda (requests, buildings/workers)

## Fluxo principal (1 minuto)

1. Coletar requests do MineColonies e normalizar para um modelo interno
2. Resolver candidatos (equivalencias entre mods + tiers) respeitando progressao
3. Inspecionar destino e calcular faltante real (nao craftar cegamente)
4. Consultar ME (estoque/craftavel) e abrir craft apenas do faltante
5. Exportar itens ao destino e atualizar estado
6. Renderizar snapshots na UI e registrar logs estruturados

## Principios que guiam o codigo

- **Estado explicito + retries**: evita craft duplicado e falhas silenciosas
- **Snapshot para UI**: UI nao faz IO de perifericos; apenas renderiza
- **Integracoes isoladas**: MineColonies/ME/destinos em modulos dedicados
- **Operacao primeiro**: logs e UI sao parte do produto (diagnostico claro)

## Onde comecar a ler

- `docs/LEIA-ME-DO-CODIGO.md`
- `docs/ARCHITECTURE.md`
- `docs/PITFALLS.md`

