# Pesquisa de Stack

**Domínio:** automação de colônia em Minecraft com CC: Tweaked, MineColonies, Applied Energistics 2 e Advanced Peripherals
**Pesquisado em:** 2026-04-05
**Confiança:** HIGH

## Stack Recomendado

### Tecnologias Centrais

| Tecnologia | Versão | Papel | Por que é recomendada |
|------------|--------|-------|------------------------|
| CC: Tweaked | compatível com o modpack instalado | Runtime Lua, sistema de arquivos, periféricos, paralelismo e UI em monitores | É a base nativa para automação com computadores, monitores, modems, inventários e APIs como `parallel`, `peripheral`, `term`, `window`, `settings` e `os` |
| Advanced Peripherals | série 0.7.x compatível com o pack | Ponte de integração com MineColonies e AE2 | Fornece `colonyIntegrator` para ler a colônia e `meBridge` para consultar estoque, exportar itens e iniciar autocrafting |
| Applied Energistics 2 | compatível com o modpack instalado | Estoque central, padrões de autocrafting e entrega logística | É o backend ideal para disponibilidade de itens, craft sob demanda e controle fino do que já existe no sistema |
| MineColonies | compatível com o modpack instalado | Origem das requisições de NPCs e construções | A colônia gera o problema de negócio real: pedidos variáveis, prioridades e destinos que exigem reconciliação automática |

### Bibliotecas e APIs de Apoio

| Biblioteca/API | Versão | Papel | Quando usar |
|----------------|--------|-------|-------------|
| `parallel` | nativa do CC: Tweaked | Executar loops de coleta, processamento, renderização e logs sem travar a UI | Sempre que a aplicação precisar monitorar múltiplas fontes simultaneamente |
| `window` | nativa do CC: Tweaked | Criar regiões de renderização e paginação em monitores | Para compor tabelas, cabeçalhos e áreas de status sem redesenhar tudo |
| `textutils` / `cc.pretty` | nativas do CC: Tweaked | Formatação de texto, serialização e depuração controlada | Para logs, dumps diagnósticos e inspeção de tabelas |
| `inventory` peripheral methods | nativas do CC: Tweaked | Leitura de slots de baús e inventários conectados | Para validar o destino antes de craftar ou entregar itens |
| `settings` | nativa do CC: Tweaked | Persistência simples de preferências locais | Útil para flags de diagnóstico, refresh e defaults operacionais |

### Ferramentas de Desenvolvimento

| Ferramenta | Papel | Notas |
|-----------|-------|-------|
| Advanced Monitor | UI operacional | Dois monitores separados reduzem ruído cognitivo: fila de requisições em um, visão resumida da colônia no outro |
| Modem com rede de periféricos | Descoberta e acesso remoto | Facilita desacoplamento físico entre computador, monitores, ME Bridge, integrador e inventários |
| Logs em arquivos rotativos | Observabilidade contínua | Essencial para operação autônoma e diagnóstico pós-falha em mundos longos |

## Instalação

```bash
# Não há pacotes externos.
# A instalação depende do modpack conter:
# - CC: Tweaked
# - Advanced Peripherals
# - Applied Energistics 2
# - MineColonies
#
# No computador:
# - startup.lua na raiz
# - config.ini na raiz
# - módulos auxiliares em subpastas
```

## Alternativas Consideradas

| Recomendado | Alternativa | Quando usar a alternativa |
|-------------|-------------|---------------------------|
| `meBridge` do Advanced Peripherals | `rsBridge` | Apenas se o backend de armazenamento for Refined Storage em vez de AE2 |
| Loop orientado a polling + filas internas | Script monolítico linear | Só em protótipos muito pequenos, quando não houver UI dupla, retentativas ou múltiplas integrações |
| Matching por nome técnico + dano | Matching por NBT completo | Quando o pack depender fortemente de itens encantados, personalizados ou com NBT indispensável |

## O Que NÃO Usar

| Evitar | Por quê | Usar no lugar |
|--------|---------|---------------|
| Script único gigante em `startup.lua` | Dificulta manutenção, testes locais e evolução da automação | Núcleo pequeno de bootstrap e módulos funcionais em subpastas |
| Crafting cego sem checar destino | Gera excesso de craft, desperdício e loops de entrega | Reconciliação entre pedido, estoque ME e conteúdo real do destino |
| Dependência de nomes visuais para matching | `displayName` varia com idioma e não é chave confiável | `name` técnico do item e metadados básicos |
| Exportar itens ao baú ao lado do computador | O ME Bridge exporta para inventário adjacente a ele, não ao computador | Inventário adjacente ao bridge ou `exportItemToPeripheral` com nome exato do container |

## Padrões de Stack por Variante

**Se o mundo tiver toda a rede em modem:**
- Usar descoberta por `peripheral.find` e nomes configuráveis
- Porque isso reduz acoplamento físico e facilita expansão

**Se o destino de entrega for sempre adjacente ao bridge:**
- Priorizar `exportItem`
- Porque simplifica a logística e reduz dependência de nomes de periféricos

**Se o destino puder estar em qualquer ponto da rede:**
- Usar `exportItemToPeripheral`
- Porque permite entregar diretamente ao inventário nomeado sem relocar o computador

## Compatibilidade de Versões

| Componente | Compatível com | Notas |
|------------|----------------|-------|
| Advanced Peripherals 0.7 docs | MineColonies instalado | O `colonyIntegrator` depende explicitamente do mod MineColonies |
| Advanced Peripherals 0.7 docs | Applied Energistics 2 instalado | O `meBridge` depende do AE2 e usa um canal do sistema ME |
| MineColonies wiki atual | 1.20.1 e 1.21.1 | A wiki indica foco nessas versões recentes |
| Advanced Peripherals docs | 1.20.1, 1.20.4 e 1.21.1 entre versões suportadas | Validar contra a versão real do modpack antes da implementação final |

## Fontes

- https://tweaked.cc/ — APIs nativas do CC: Tweaked, monitores, periféricos, eventos e paralelismo
- https://docs.advanced-peripherals.de/0.7/ — visão geral e suporte de versões do Advanced Peripherals
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/colony_integrator/ — capacidades do `colonyIntegrator`
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/me_bridge/ — capacidades do `meBridge`, crafting e exportação
- https://minecolonies.com/wiki/ — contexto funcional do MineColonies e natureza das colônias/NPCs

---
*Pesquisa de stack para: automação MineColonies-ME*
*Pesquisado em: 2026-04-05*
