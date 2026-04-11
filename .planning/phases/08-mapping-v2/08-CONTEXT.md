# Phase 08: Mapping v2 (Estrutura + Comportamento)

## Objetivo

Evoluir o sistema de mapeamentos para um formato mais expressivo e previsível, sem depender de equivalências padrão obrigatórias.

## Problemas que motivam

- Estrutura atual é limitada para representar regras (preferências, bloqueios, prioridades por classe/tier/mod).
- Editor atual cobre apenas equivalências básicas e tier/classe por item.
- Mudanças de formato exigem migração segura e validação.

## Escopo

- Definir um `mappings.json` v2 (com `version` novo) e compatibilidade:
  - carregar v1 e migrar para estrutura interna v2
  - opcionalmente persistir migração em arquivo (configurável)
- Expandir comportamento de resolução:
  - preferências explícitas (ex.: vanilla_first por classe)
  - regras de prioridade por tier e disponibilidade
- Atualizar o `startup map` para suportar o v2.

## Fora de escopo

- Forçar um dataset padrão de equivalências.
- Matching avançado por NBT completo (continua v2+).

