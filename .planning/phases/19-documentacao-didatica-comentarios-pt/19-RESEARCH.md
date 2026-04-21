# Phase 19: Documentacao Didatica + Comentarios (PT) - Research

**Date:** 2026-04-21
**Confidence:** HIGH

## Summary

Esta fase e essencialmente de documentacao + comentarios. O risco principal nao e tecnico: e virar documentacao morta (nao linkada, nao atualizada) ou comentar demais (ruido) e atrapalhar manutencao. A estrategia mais segura e:

- Centralizar o guia didatico em `docs/LEIA-ME-DO-CODIGO.md` (1 arquivo principal).
- Expor via `README.md` com secao "Documentacao" e links diretos.
- Derivar 3 docs publicos em `docs/` a partir de `.planning/research/` (sem depender de `.planning/` para o leitor do repo).
- Inserir comentarios curtos e focados (por que/invariantes/contratos) nos modulos-chave listados no CONTEXT.

## Inputs (fontes internas)

- `.planning/phases/19-documentacao-didatica-comentarios-pt/19-CONTEXT.md` (decisoes travadas)
- `.planning/research/ARCHITECTURE.md` (base para `docs/ARCHITECTURE.md`)
- `.planning/research/PITFALLS.md` (base para `docs/PITFALLS.md`)
- `.planning/research/SUMMARY.md` (base para `docs/SUMMARY.md`)
- `README.md` (ponto de entrada atual)

## Deliverables recomendados (concretos)

### 1) docs/LEIA-ME-DO-CODIGO.md (guia central)

Estrutura sugerida (com ancoras):

- Objetivo do projeto (1 paragrafo)
- Como pensar o sistema (camadas: peripherals -> modules -> engine/scheduler -> UI)
- Fluxo principal (request -> normalize -> escolher candidato -> checar destino -> craft -> entrega -> logs/UI)
- "Mapa do repo" (diretorios + responsabilidades)
- Roteiro de leitura (ordem + o que procurar em cada arquivo)
- Glossario rapido (requestId, target, chosen, missing, retry, snapshot)
- Operacao (como rodar, como usar doctor, como rodar testes)
- Onde mexer quando X quebra (links para PITFALLS + pontos de integracao)

### 2) docs/ARCHITECTURE.md, docs/PITFALLS.md, docs/SUMMARY.md

Derivar de `.planning/research/*` com foco em leitor do repo:

- Remover conteudo redundante de "pesquisado em" se nao agregar
- Manter diagramas/fluxos e tabelas utilitarias
- Garantir que links internos apontem para caminhos do repo (sem depender de ferramentas GSD)

### 3) README.md: secao "Documentacao"

Inserir secao com links diretos (em ordem de leitura):

- docs/LEIA-ME-DO-CODIGO.md
- docs/SUMMARY.md
- docs/ARCHITECTURE.md
- docs/PITFALLS.md

### 4) Comentarios nos modulos-chave

Padrao recomendado (para evitar ruido):

- Comentario de cabecalho por modulo (3-8 linhas), descrevendo:
  - responsabilidade
  - invariantes/contratos (inputs/outputs)
  - quando mexer aqui vs em outro modulo
- Comentarios pontuais apenas em:
  - conversoes/mapeamentos (ex.: normalizacao de request)
  - politicas de retry/backoff/budget
  - regras de "nao fazer IO aqui" (ex.: snapshot/UI)

Recomendacao: manter comentarios no codigo em portugues ASCII (sem acentos) para evitar problemas em editores/monitores do CC.

## Pontos do codebase que merecem destaque no guia

- `startup.lua` -> ponto de entrada
- `lib/bootstrap.lua` -> carrega config, resolve perifericos, liga modulos
- `modules/scheduler.lua` -> loop e budget
- `modules/engine.lua` -> tick, estado, work por request
- `modules/snapshot.lua` -> contrato de snapshot (UI nao faz IO)
- `components/ui.lua` -> render dual-monitor baseado em snapshot
- `modules/minecolonies.lua` -> leitura/normalizacao de requests
- `modules/me.lua` -> consulta/craft/exportacao, tratamento de falhas

## Validation Architecture

Como esta fase mexe em docs e comentarios, a verificacao deve ser por:

- Presenca de arquivos em `docs/` e links no `README.md`
- Conteudo minimo (secao/ancoras) no guia didatico
- `startup test` verde apos qualquer mudanca em modulo critico (se comentarios alterarem arquivos executados)

